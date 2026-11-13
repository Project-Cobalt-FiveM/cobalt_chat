<script lang="ts" module>
  export interface Row {
    key: string;
    title: string;
    match?: string;
    args?: string;
    detail: string;
  }
</script>

<script lang="ts">
  let { rows, highlight, onPick }: { rows: Row[]; highlight: number; onPick: (index: number) => void } = $props();
</script>

<div role="listbox" class="flex animate-enter flex-col gap-0.5 rounded-lg border border-border bg-card p-1">
  {#each rows as row, i (row.key)}
    <button
      type="button"
      role="option"
      tabindex="-1"
      aria-selected={i === highlight}
      onmousedown={e => e.preventDefault()}
      onclick={() => onPick(i)}
      class={[
        'flex items-baseline gap-2 rounded-md px-2 py-1.5 text-left',
        i === highlight ? 'bg-secondary' : 'hover:bg-muted',
      ]}
    >
      <span class="shrink-0 text-label font-semibold text-foreground">
        {#if row.match}<span class="text-cobalt-foreground">{row.match}</span>{/if}{row.title}
        {#if row.args}<span class="font-medium text-faint"> {row.args}</span>{/if}
      </span>
      <span class="min-w-0 flex-1 truncate text-right text-tag text-muted-foreground">{row.detail}</span>
    </button>
  {/each}
</div>
