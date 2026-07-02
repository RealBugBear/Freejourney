// supabase/functions/chat-triage-bot/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const BOT_USER_ID = Deno.env.get('BOT_USER_ID')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface RequestPayload {
  channel_id: string;
  content: string;
  locale: 'de' | 'en';
}

interface FaqRow {
  id: string;
  keywords: string[];
  response_de: string;
  response_en: string;
  escalate_to_trainer: boolean;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const payload: RequestPayload = await req.json();
    const { channel_id, content, locale } = payload;

    if (!channel_id || !content) {
      return new Response(JSON.stringify({ error: 'Missing channel_id or content' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Use service role key to verify caller identity and let the bot post as BOT_USER_ID.
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabase.auth.getUser(jwt);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Verify user is a member of this channel before any bot write or trainer notification.
    const { data: membership } = await supabase
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channel_id)
      .eq('user_id', user.id)
      .single();

    if (!membership) {
      return new Response(JSON.stringify({ error: 'Not a channel member' }), {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const { data: faqs, error: faqError } = await supabase
      .from('bot_faqs')
      .select('*');

    if (faqError) throw faqError;

    const contentLower = content.toLowerCase().trim();
    const match = (faqs as FaqRow[]).find((faq) =>
      faq.keywords.some((kw) => contentLower.includes(kw.toLowerCase()))
    );

    if (match) {
      const response = locale === 'en' ? match.response_en : match.response_de;

      await supabase.from('chat_messages').insert({
        channel_id,
        sender_id: BOT_USER_ID,
        content: response,
        is_bot_response: true,
        is_call_request: false,
      });

      if (match.escalate_to_trainer) {
        await notifyTrainer(supabase, channel_id, content);
      }
    } else {
      // No match — escalate and inform user.
      const escalationMsg = locale === 'en'
        ? 'I have forwarded your question to your trainer.'
        : 'Ich habe deine Frage an deinen Trainer weitergeleitet.';

      await supabase.from('chat_messages').insert({
        channel_id,
        sender_id: BOT_USER_ID,
        content: escalationMsg,
        is_bot_response: true,
        is_call_request: false,
      });

      await notifyTrainer(supabase, channel_id, content);
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Triage bot error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

async function notifyTrainer(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  channel_id: string,
  originalContent: string
): Promise<void> {
  // Find trainer in this channel (role = 'moderator').
  const { data: members } = await supabase
    .from('chat_channel_members')
    .select('user_id')
    .eq('channel_id', channel_id)
    .eq('role', 'moderator');

  if (!members || members.length === 0) return;

  // Fetch trainer device tokens for FCM.
  const trainerIds: string[] = members.map((m: { user_id: string }) => m.user_id);

  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('token')
    .in('user_id', trainerIds);

  if (!tokens || tokens.length === 0) return;

  // Send FCM push via Firebase legacy HTTP API.
  // Requires FIREBASE_SERVER_KEY env var to be set in Supabase Edge Function secrets.
  const fcmKey = Deno.env.get('FIREBASE_SERVER_KEY');
  if (!fcmKey) return;

  for (const { token } of tokens) {
    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        Authorization: `key=${fcmKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: 'Neue Klienten-Frage',
          body: originalContent.length > 80
            ? `${originalContent.substring(0, 80)}…`
            : originalContent,
        },
        data: {
          type: 'chat_escalation',
          channel_id,
        },
      }),
    });
  }
}
