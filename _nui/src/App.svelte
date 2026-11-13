<script lang="ts">
  import { onMount } from 'svelte';
  import ChatBox from './components/ChatBox.svelte';
  import ChatInput from './components/ChatInput.svelte';
  import { NO_UNREAD, TABS, mentionPattern, tabShows, type TabId } from './lib/channels';
  import { DEFAULT_CONFIG, LOCAL, MOCK_CONFIG, MOCK_MESSAGES, MOCK_SUGGESTIONS } from './lib/mock';
  import { fetchNui, inGame, onNuiMessage } from './lib/nui';
  import type { ChatChannel, ChatConfig, ChatMessage, ChatMode, ChatScope, ChatStyle, ChatSuggestion, NuiMessage } from './lib/types';

  const HISTORY_LIMIT = 30;

  let config: ChatConfig = $state(inGame ? DEFAULT_CONFIG : MOCK_CONFIG);
  let messages: ChatMessage[] = $state(inGame ? [] : MOCK_MESSAGES);
  let suggestions: ChatSuggestion[] = $state(inGame ? [] : MOCK_SUGGESTIONS);
  let open = $state(!inGame);
  let mode = $state<ChatMode>('active');
  let popped = $state(false);
  let tab = $state<TabId>('all');
  let unread: Record<TabId, number> = $state({ ...NO_UNREAD });
  let channel: ChatChannel = $state(LOCAL);
  let history: string[] = $state([]);
  let fadeTimer: number | undefined;

  const mention = $derived(mentionPattern(config.mentionName));
  const CLOSED_FEED_LIMIT = 30;

  const shown = $derived(open ? messages.filter(m => tabShows(tab, m)) : messages.slice(-CLOSED_FEED_LIMIT));
  const feedUp = $derived(open || mode === 'shown' || (mode === 'active' && popped));

  function scheduleFade() {
    window.clearTimeout(fadeTimer);
    fadeTimer = window.setTimeout(() => (popped = false), config.idleFadeMs);
  }

  function hide() {
    open = false;

    if (mode === 'active') {
      popped = true;
      scheduleFade();
      return;
    }

    window.clearTimeout(fadeTimer);
    popped = false;
  }

  function show() {
    window.clearTimeout(fadeTimer);
    open = true;
  }

  function close() {
    hide();
    fetchNui('blur', {});
  }

  function receive(message: ChatMessage) {
    messages = [...messages, message].slice(-config.maxMessages);

    if (open && !tabShows(tab, message)) {
      for (const t of TABS) if (t.id !== 'all' && t.shows(message)) unread[t.id] += 1;
    }

    if (!open && mode === 'active') {
      popped = true;
      scheduleFade();
    }
  }

  function addSuggestions(added: ChatSuggestion[]) {
    if (added.length === 0) return;
    const incoming = new Map(added.map(s => [s.name, s]));
    suggestions = [...suggestions.filter(s => !incoming.has(s.name)), ...incoming.values()];
  }

  function handle(message: NuiMessage) {
    switch (message.action) {
      case 'boot':
        config = { ...config, ...message.config };
        suggestions = message.suggestions;
        if (message.mode) mode = message.mode;
        break;
      case 'mode':
        mode = message.mode;
        break;
      case 'identity':
        config.mentionName = message.name;
        break;
      case 'renderMessage':
        receive(message.message);
        break;
      case 'clear':
        messages = [];
        break;
      case 'focusInput':
        show();
        break;
      case 'blurInput':
        hide();
        break;
      case 'addSuggestions':
        addSuggestions(message.suggestions);
        break;
      case 'removeSuggestion':
        suggestions = suggestions.filter(s => s.name !== message.name);
        break;
      default: {
        const exhaustive: never = message;
        return exhaustive;
      }
    }
  }

  onMount(() => {
    const stop = onNuiMessage(handle);
    fetchNui('ready', {});
    return stop;
  });

  function onWindowKeydown(e: KeyboardEvent) {
    if (inGame || open || e.key !== 't') return;
    e.preventDefault();
    show();
  }

  function selectTab(id: TabId) {
    tab = id;
    unread[id] = 0;
  }

  function mockScope(command: string): ChatScope {
    if (command === 'ooc') return 'global';
    if (command === 'ac') return 'admin';
    return 'proximity';
  }

  function mockStyle(command: string): ChatStyle {
    if (command === 'me') return 'action';
    if (command === 'do') return 'narrative';
    return 'speech';
  }

  function send(value: string) {
    if (!value) {
      close();
      return;
    }

    history = [value, ...history.filter(h => h !== value)].slice(0, HISTORY_LIMIT);

    if (!inGame) {
      receive({
        id: `mock-${Date.now()}`,
        author: 'You',
        channel: channel.command,
        scope: mockScope(channel.command),
        style: mockStyle(channel.command),
        label: channel.label,
        content: value,
        timestamp: Date.now(),
      });
      close();
      return;
    }

    const content = value.startsWith('/') || channel.command === 'say' ? value : `/${channel.command} ${value}`;
    hide();
    fetchNui('send', { content });
  }
</script>

<svelte:window onkeydown={onWindowKeydown} />

<main
  class={[
    'fixed top-8 left-8 flex w-[25rem] flex-col gap-1.5 transition-opacity duration-300',
    feedUp ? 'opacity-100' : 'opacity-0',
    open ? 'pointer-events-auto' : 'pointer-events-none',
  ]}
>
  {#if open || shown.length > 0}
    <ChatBox messages={shown} {open} {tab} {unread} {mention} onTab={selectTab} />
  {/if}
  {#if open}
    <ChatInput
      maxLen={config.maxMessageLen}
      channels={config.channels}
      {channel}
      {suggestions}
      {history}
      onChannel={c => (channel = c)}
      onSend={send}
      onEscape={close}
    />
  {/if}
</main>
