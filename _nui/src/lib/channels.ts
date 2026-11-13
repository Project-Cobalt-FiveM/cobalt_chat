import type { ChatMessage } from './types';

export type TabId = 'all' | 'local' | 'ooc' | 'staff';

export interface Tab {
  id: TabId;
  label: string;
  shows: (message: ChatMessage) => boolean;
}

export const TABS: readonly Tab[] = [
  { id: 'all', label: 'All', shows: () => true },
  { id: 'local', label: 'Local', shows: m => m.scope === 'proximity' },
  { id: 'ooc', label: 'OOC', shows: m => m.channel === 'ooc' },
  { id: 'staff', label: 'Staff', shows: m => m.scope === 'admin' },
];

export const NO_UNREAD: Readonly<Record<TabId, number>> = { all: 0, local: 0, ooc: 0, staff: 0 };

export const tabShows = (id: TabId, message: ChatMessage): boolean => TABS.some(t => t.id === id && t.shows(message));

const TAG_CLASSES = {
  server: 'bg-cobalt text-foreground',
  danger: 'bg-destructive text-foreground',
  staff: 'bg-warning text-background',
  neutral: 'bg-secondary border border-input text-foreground',
} as const;

export function tagClasses(message: ChatMessage): string {
  if (message.style === 'system') return TAG_CLASSES.server;
  if (message.channel === '911') return TAG_CLASSES.danger;
  if (message.scope === 'admin') return TAG_CLASSES.staff;
  return TAG_CLASSES.neutral;
}

const pad = (value: number): string => String(value).padStart(2, '0');

export function formatTime(timestamp: number): string {
  const date = new Date(timestamp);
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function mentionPattern(name: string | null): RegExp | null {
  if (!name) return null;
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`(@${escaped})(?![\\w])`, 'gi');
}
