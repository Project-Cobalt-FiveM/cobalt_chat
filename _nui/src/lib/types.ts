export type ChatScope = 'proximity' | 'global' | 'admin';
export type ChatStyle = 'speech' | 'action' | 'narrative' | 'system';

export interface ChatMessage {
  id: string;
  author: string;
  channel: string;
  scope: ChatScope;
  style: ChatStyle;
  label: string;
  content: string;
  timestamp: number;
}

export const CHAT_MODES = ['active', 'shown', 'inactive'] as const;
export type ChatMode = (typeof CHAT_MODES)[number];

export interface ChatChannel {
  command: string;
  label: string;
}

export interface ChatParam {
  name: string;
  help: string;
}

export interface ChatSuggestion {
  name: string;
  help: string;
  params?: ChatParam[];
}

export interface ChatConfig {
  idleFadeMs: number;
  maxMessages: number;
  maxMessageLen: number;
  channels: ChatChannel[];
  mentionName: string | null;
}

export type NuiMessage =
  | { action: 'boot'; config: Partial<ChatConfig>; suggestions: ChatSuggestion[]; mode: ChatMode | null }
  | { action: 'mode'; mode: ChatMode }
  | { action: 'identity'; name: string | null }
  | { action: 'renderMessage'; message: ChatMessage }
  | { action: 'clear' }
  | { action: 'focusInput' }
  | { action: 'blurInput' }
  | { action: 'addSuggestions'; suggestions: ChatSuggestion[] }
  | { action: 'removeSuggestion'; name: string };

export type NuiCallbacks = {
  send: { content: string };
  blur: Record<string, never>;
  ready: Record<string, never>;
};

type Fields = Record<string, unknown>;

const SCOPES: readonly ChatScope[] = ['proximity', 'global', 'admin'];
const STYLES: readonly ChatStyle[] = ['speech', 'action', 'narrative', 'system'];

const isFields = (value: unknown): value is Fields => typeof value === 'object' && value !== null;
const isScope = (value: unknown): value is ChatScope => SCOPES.some(s => s === value);
const isStyle = (value: unknown): value is ChatStyle => STYLES.some(s => s === value);
export const isChatMode = (value: unknown): value is ChatMode => CHAT_MODES.some(m => m === value);

const toText = (value: unknown): string => (typeof value === 'string' ? value : '');
const toNumber = (value: unknown): number | undefined =>
  typeof value === 'number' && Number.isFinite(value) ? value : undefined;

function toList(value: unknown): unknown[] {
  if (Array.isArray(value)) return value;
  if (!isFields(value)) return [];
  return 'name' in value ? [value] : Object.values(value);
}

export function toChatMessage(value: unknown): ChatMessage | null {
  if (!isFields(value)) return null;

  const { id, author, channel, scope, style, label, content, timestamp } = value;

  if (typeof id !== 'string' || typeof author !== 'string' || typeof channel !== 'string') return null;
  if (typeof label !== 'string' || typeof content !== 'string' || typeof timestamp !== 'number') return null;
  if (!isScope(scope) || !isStyle(style)) return null;

  return { id, author, channel, scope, style, label, content, timestamp };
}

function toParam(value: unknown): ChatParam[] {
  if (!isFields(value) || typeof value.name !== 'string') return [];
  return [{ name: value.name, help: toText(value.help) }];
}

function toSuggestion(value: unknown): ChatSuggestion[] {
  if (!isFields(value) || typeof value.name !== 'string' || value.name === '') return [];

  const params = toList(value.params).flatMap(toParam);

  return [{ name: value.name, help: toText(value.help), params: params.length > 0 ? params : undefined }];
}

export const toSuggestions = (value: unknown): ChatSuggestion[] => toList(value).flatMap(toSuggestion);

function toChannel(value: unknown): ChatChannel[] {
  if (!isFields(value) || typeof value.command !== 'string' || typeof value.label !== 'string') return [];
  return [{ command: value.command, label: value.label }];
}

function toConfig(value: unknown): Partial<ChatConfig> {
  if (!isFields(value)) return {};

  const config: Partial<ChatConfig> = {
    mentionName: typeof value.mentionName === 'string' ? value.mentionName : null,
  };

  const idleFadeMs = toNumber(value.idleFadeMs);
  const maxMessages = toNumber(value.maxMessages);
  const maxMessageLen = toNumber(value.maxMessageLen);
  const channels = toList(value.channels).flatMap(toChannel);

  if (idleFadeMs !== undefined) config.idleFadeMs = idleFadeMs;
  if (maxMessages !== undefined) config.maxMessages = maxMessages;
  if (maxMessageLen !== undefined) config.maxMessageLen = maxMessageLen;
  if (channels.length > 0) config.channels = channels;

  return config;
}

export function toNuiMessage(value: unknown): NuiMessage | null {
  if (!isFields(value)) return null;

  switch (value.action) {
    case 'boot':
      return {
        action: 'boot',
        config: toConfig(value.config),
        suggestions: toSuggestions(value.suggestions),
        mode: isChatMode(value.mode) ? value.mode : null,
      };
    case 'mode':
      return isChatMode(value.mode) ? { action: 'mode', mode: value.mode } : null;
    case 'identity':
      return { action: 'identity', name: typeof value.name === 'string' && value.name !== '' ? value.name : null };
    case 'renderMessage': {
      const message = toChatMessage(value.message);
      return message ? { action: 'renderMessage', message } : null;
    }
    case 'clear':
    case 'focusInput':
    case 'blurInput':
      return { action: value.action };
    case 'addSuggestion':
      return { action: 'addSuggestions', suggestions: toSuggestions(value.suggestion) };
    case 'addSuggestions':
      return { action: 'addSuggestions', suggestions: toSuggestions(value.suggestions) };
    case 'removeSuggestion':
      return typeof value.name === 'string' ? { action: 'removeSuggestion', name: value.name } : null;
    default:
      return null;
  }
}
