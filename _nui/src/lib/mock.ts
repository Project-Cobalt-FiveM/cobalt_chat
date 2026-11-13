import type { ChatChannel, ChatConfig, ChatMessage, ChatSuggestion } from './types';

export const LOCAL: ChatChannel = { command: 'say', label: 'Local' };

export const DEFAULT_CONFIG: ChatConfig = {
  idleFadeMs: 3000,
  maxMessages: 1000,
  maxMessageLen: 240,
  channels: [LOCAL],
  mentionName: null,
};

const at = (hours: number, minutes: number): number => new Date().setHours(hours, minutes, 0, 0);

export const MOCK_CONFIG: ChatConfig = {
  ...DEFAULT_CONFIG,
  mentionName: 'Donovan',
  channels: [
    LOCAL,
    { command: 'ooc', label: 'OOC' },
    { command: 'me', label: 'Me' },
    { command: 'do', label: 'Do' },
    { command: 'ac', label: 'Staff' },
  ],
};

export const MOCK_MESSAGES: ChatMessage[] = [
  { id: 'm1', author: 'Announcement', channel: 'server', scope: 'global', style: 'system', label: 'Server', content: 'Restart in 30 minutes. Park your vehicles somewhere safe.', timestamp: at(21, 4) },
  { id: 'm2', author: 'Jamie Ortiz', channel: 'ooc', scope: 'global', style: 'speech', label: 'OOC', content: 'anyone up for a race at the docks after the restart?', timestamp: at(21, 6) },
  { id: 'm3', author: 'Donovan Sinclair', channel: 'me', scope: 'proximity', style: 'action', label: 'Me', content: 'checks his phone and sighs.', timestamp: at(21, 7) },
  { id: 'm4', author: 'Dispatch', channel: '911', scope: 'global', style: 'speech', label: '911', content: 'Shots fired near Legion Square. Units respond.', timestamp: at(21, 8) },
  { id: 'm5', author: 'Ash', channel: 'ac', scope: 'admin', style: 'speech', label: 'Staff', content: 'Claimed report #214.', timestamp: at(21, 9) },
  { id: 'm6', author: 'Maya Chen', channel: 'say', scope: 'proximity', style: 'speech', label: 'Local', content: '@Donovan grab me a *coffee* on your way?', timestamp: at(21, 10) },
];

export const MOCK_SUGGESTIONS: ChatSuggestion[] = [
  { name: '/me', help: 'Describe what your character does', params: [{ name: 'action', help: '' }] },
  { name: '/mask', help: 'Put on or take off your mask' },
  { name: '/msg', help: 'Send a private message', params: [{ name: 'id', help: '' }, { name: 'message', help: '' }] },
  { name: '/ooc', help: 'OOC channel', params: [{ name: 'message', help: '' }] },
];
