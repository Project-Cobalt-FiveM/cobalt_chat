<script lang="ts">
  import type { ChatMessage } from '../lib/types';
  import { parseChatText, segmentClasses } from '../lib/format';
  import { formatTime, tagClasses } from '../lib/channels';

  let { message, mention }: { message: ChatMessage; mention: RegExp | null } = $props();

  const segments = $derived(parseChatText(message.content));
  const mentionsMe = $derived(mention !== null && message.content.split(mention).length > 1);
  const emote = $derived(message.style === 'action' || message.style === 'narrative');
</script>

<div
  class={[
    'flex shrink-0 animate-enter flex-col gap-0.5 rounded-md border bg-muted px-2.5 py-1.5',
    mentionsMe ? 'border-cobalt' : 'border-muted',
  ]}
>
  <div class="flex items-center gap-1.5">
    <span class={['flex h-4 shrink-0 items-center rounded-sm px-1 text-tag font-semibold', tagClasses(message)]}>
      {message.label}
    </span>
    <span class="truncate text-label font-semibold text-foreground">{message.author}</span>
    <time class="ml-auto shrink-0 text-tag text-faint tabular-nums">{formatTime(message.timestamp)}</time>
  </div>
  <p class={['text-body break-words', emote ? 'text-muted-foreground italic' : 'text-message']}>
    {#each segments as segment, i (i)}
      <span class={segmentClasses(segment)}>
        {#if mention}
          {#each segment.text.split(mention) as part, j (j)}
            {#if j % 2 === 1}
              <span class="font-semibold text-cobalt-foreground">{part}</span>
            {:else}
              {part}
            {/if}
          {/each}
        {:else}
          {segment.text}
        {/if}
      </span>
    {/each}
  </p>
</div>
