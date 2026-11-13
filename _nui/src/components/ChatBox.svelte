<script lang="ts">
  import type { ChatMessage as Message } from '../lib/types';
  import { TABS, type TabId } from '../lib/channels';
  import ChatMessage from './ChatMessage.svelte';

  interface Props {
    messages: Message[];
    open: boolean;
    tab: TabId;
    unread: Record<TabId, number>;
    mention: RegExp | null;
    onTab: (tab: TabId) => void;
  }

  let { messages, open, tab, unread, mention, onTab }: Props = $props();

  const STICK_THRESHOLD_PX = 16;

  let feed: HTMLDivElement | undefined = $state();
  let stuck = true;

  $effect.pre(() => {
    void tab;
    void open;
    stuck = true;
  });

  $effect(() => {
    void messages.length;
    void tab;
    void open;
    if (feed && stuck) feed.scrollTop = feed.scrollHeight;
  });

  function onScroll() {
    if (feed) stuck = feed.scrollHeight - feed.scrollTop - feed.clientHeight < STICK_THRESHOLD_PX;
  }
</script>

<section
  class={['flex shrink-0 flex-col rounded-lg border border-border bg-card p-1', open ? 'h-[16.25rem]' : 'max-h-[16.25rem]']}
>
  {#if open}
    <nav class="flex items-center gap-0.5 px-0.5 pt-0.5 pb-1.5" aria-label="Chat channels">
      {#each TABS as t (t.id)}
        {@const active = t.id === tab}
        {@const count = unread[t.id]}
        <button
          type="button"
          onmousedown={e => e.preventDefault()}
          onclick={() => onTab(t.id)}
          aria-pressed={active}
          class={[
            'flex h-6 items-center gap-1 rounded-md px-2 text-label font-medium transition-colors',
            active ? 'bg-secondary text-foreground' : 'text-muted-foreground hover:text-foreground',
          ]}
        >
          {t.label}
          {#if count > 0}
            <span
              class="flex h-3.5 min-w-3.5 items-center justify-center rounded-md bg-cobalt px-1 text-pill font-bold text-foreground tabular-nums"
            >
              {count > 99 ? '99+' : count}
            </span>
          {/if}
        </button>
      {/each}
    </nav>
    <div class="mx-1 mb-1 h-px shrink-0 bg-border"></div>
  {/if}
  <div bind:this={feed} onscroll={onScroll} class="feed-scroll flex min-h-0 flex-1 flex-col gap-1" aria-live="polite">
    {#each messages as message (message.id)}
      <ChatMessage {message} {mention} />
    {:else}
      <p class="m-auto text-label text-faint">No messages yet</p>
    {/each}
  </div>
</section>
