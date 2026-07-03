// supabase/functions/chat-triage-bot/index.ts
//
// DISABLED for launch (backlog P0.2, 2026-07-03).
//
// The keyword/FAQ triage bot was never a reviewed product feature: the live
// DB shows zero bot messages ever sent, its escalation copy promised trainer
// forwarding backed by the shut-down FCM legacy API, and its seeded FAQ
// content needs product/legal review. The previous implementation held a
// service-role client that could write into private chat channels — this stub
// exists so the deployed endpoint keeps NO privileged code path at all.
//
// App builds up to v1.0.5 fire-and-forget a call to this endpoint on every
// direct-chat message (removed app-side in the same backlog item), so the
// stub must answer fast and harmlessly. It touches no database, reads no
// secrets, and writes nothing.
//
// Re-enabling a chatbot is a post-launch product decision — see the backlog's
// "Open questions / parked" section.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

serve((req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  return new Response(
    JSON.stringify({ error: 'chat-triage-bot is disabled' }),
    { status: 410, headers: { 'Content-Type': 'application/json' } },
  );
});
