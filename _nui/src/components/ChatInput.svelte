<script lang="ts">
  import CaretDownIcon from 'phosphor-svelte/lib/CaretDownIcon';
  import type { ChatChannel, ChatSuggestion } from '../lib/types';
  import Suggestions, { type Row } from './Suggestions.svelte';

  interface Props {
    maxLen: number;
    channels: ChatChannel[];
    channel: ChatChannel;
    suggestions: ChatSuggestion[];
    history: string[];
    onChannel: (channel: ChatChannel) => void;
    onSend: (text: string) => void;
    onEscape: () => void;
  }

  let { maxLen, channels, channel, suggestions, history, onChannel, onSend, onEscape }: Props = $props();

  const MAX_ROWS = 6;

  let text = $state('');
  let historyIdx: number | null = $state(null);
  let highlight = $state(0);
  let picking = $state(false);
  let input: HTMLInputElement | undefined = $state();

  $effect(() => {
    input?.focus();
  });

  function matchSuggestions(value: string): ChatSuggestion[] {
    if (!value.startsWith('/')) return [];
    const head = (value.split(' ')[0] ?? '').toLowerCase();
    const typedArgs = value.includes(' ');
    return suggestions
      .filter(s => (typedArgs ? s.name.toLowerCase() === head : s.name.toLowerCase().startsWith(head)))
      .slice(0, MAX_ROWS);
  }

  function suggestionRow(suggestion: ChatSuggestion, typed: string): Row {
    const match = suggestion.name.slice(0, Math.min(typed.length, suggestion.name.length));
    return {
      key: suggestion.name,
      match,
      title: suggestion.name.slice(match.length),
      args: suggestion.params?.map(p => `[${p.name}]`).join(' '),
      detail: suggestion.help,
    };
  }

  const matches = $derived(picking ? [] : matchSuggestions(text));
  const rows: Row[] = $derived(
    picking
      ? channels.map(c => ({ key: c.command, title: c.label, detail: `/${c.command}` }))
      : matches.map(s => suggestionRow(s, text.split(' ')[0] ?? '')),
  );

  function edit(value: string) {
    text = value;
    highlight = 0;
  }

  function pick(index: number) {
    if (picking) {
      const next = channels[index];
      if (next) onChannel(next);
      picking = false;
      return;
    }
    const match = matches[index];
    if (match) edit(`${match.name} `);
  }

  function togglePicker() {
    highlight = Math.max(0, channels.findIndex(c => c.command === channel.command));
    picking = !picking;
  }

  function submit() {
    const value = text.trim();
    historyIdx = null;
    edit('');
    onSend(value);
  }

  function browseHistory(older: boolean) {
    if (history.length === 0 || (historyIdx === null && !older)) return;
    const next = historyIdx === null ? 0 : historyIdx + (older ? 1 : -1);
    if (next < 0) {
      historyIdx = null;
      edit('');
      return;
    }
    const clamped = Math.min(next, history.length - 1);
    historyIdx = clamped;
    edit(history[clamped] ?? '');
  }

  function onKeydown(e: KeyboardEvent) {
    const step = e.key === 'ArrowDown' ? 1 : e.key === 'ArrowUp' ? -1 : 0;

    if (e.key === 'Enter') {
      e.preventDefault();
      if (picking) pick(highlight);
      else submit();
    } else if (e.key === 'Escape') {
      e.preventDefault();
    } else if (e.key === 'Tab') {
      e.preventDefault();
      pick(highlight);
    } else if (step !== 0 && rows.length > 0) {
      e.preventDefault();
      highlight = (highlight + step + rows.length) % rows.length;
    } else if (step !== 0) {
      e.preventDefault();
      browseHistory(step === -1);
    }
  }

  function onKeyup(e: KeyboardEvent) {
    if (e.key !== 'Escape') return;
    if (picking) {
      picking = false;
      return;
    }
    edit('');
    onEscape();
  }

  function onInput(e: Event & { currentTarget: HTMLInputElement }) {
    edit(e.currentTarget.value);
    historyIdx = null;
    picking = false;
  }
</script>

<div
  class="flex h-9 shrink-0 animate-enter items-center gap-2 rounded-lg border border-border bg-card pr-1.5 pl-1 transition-colors focus-within:border-cobalt"
>
  <button
    type="button"
    onmousedown={e => e.preventDefault()}
    onclick={togglePicker}
    aria-haspopup="listbox"
    aria-expanded={picking}
    class="flex h-7 shrink-0 items-center gap-1 rounded-md bg-secondary pr-1.5 pl-2 text-label font-medium text-foreground"
  >
    {channel.label}
    <CaretDownIcon weight="fill" size="0.625rem" class="text-muted-foreground" aria-hidden="true" />
  </button>
  <input
    bind:this={input}
    type="text"
    value={text}
    maxlength={maxLen}
    oninput={onInput}
    onkeydown={onKeydown}
    onkeyup={onKeyup}
    onblur={() => input?.focus()}
    placeholder={`Message ${channel.label}`}
    aria-label="Chat message"
    spellcheck={false}
    autocomplete="off"
    class="min-w-0 flex-1 bg-transparent text-body text-foreground caret-cobalt outline-none placeholder:text-faint"
  />
  <kbd
    class="flex h-[1.125rem] shrink-0 items-center rounded-sm bg-secondary px-1.5 font-sans text-pill font-semibold text-muted-foreground"
  >
    Enter
  </kbd>
</div>
{#if rows.length > 0}
  <Suggestions {rows} {highlight} onPick={pick} />
{/if}
