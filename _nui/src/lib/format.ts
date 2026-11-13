export interface Segment {
  text: string;
  color?: string;
  bold?: boolean;
  italic?: boolean;
  underline?: boolean;
  strike?: boolean;
}

type Marks = Omit<Segment, 'text'>;

const LEGACY_CODE = /\^([0-9*_~])/g;

const MARKDOWN: readonly [RegExp, 'bold' | 'italic' | 'strike'][] = [
  [/\*([^*\n]+)\*/g, 'bold'],
  [/_([^_\n]+)_/g, 'italic'],
  [/~([^~\n]+)~/g, 'strike'],
];

function applyCode(marks: Marks, code: string): Marks {
  if (code >= '0' && code <= '9') return { ...marks, color: `cc-${code}` };
  if (code === '*') return { ...marks, bold: !marks.bold };
  if (code === '_') return { ...marks, underline: !marks.underline };
  return { ...marks, strike: !marks.strike };
}

function parseLegacy(input: string): Segment[] {
  const segments: Segment[] = [];
  let marks: Marks = {};
  let cursor = 0;

  for (const match of input.matchAll(LEGACY_CODE)) {
    segments.push({ ...marks, text: input.slice(cursor, match.index) });
    marks = applyCode(marks, match[1] ?? '');
    cursor = match.index + match[0].length;
  }

  segments.push({ ...marks, text: input.slice(cursor) });
  return segments.filter(s => s.text.length > 0);
}

function splitMarkdown(segment: Segment, pattern: RegExp, mark: 'bold' | 'italic' | 'strike'): Segment[] {
  const parts: Segment[] = [];
  let cursor = 0;

  for (const match of segment.text.matchAll(pattern)) {
    parts.push({ ...segment, text: segment.text.slice(cursor, match.index) });
    parts.push({ ...segment, text: match[1] ?? '', [mark]: true });
    cursor = match.index + match[0].length;
  }

  parts.push({ ...segment, text: segment.text.slice(cursor) });
  return parts.filter(s => s.text.length > 0);
}

export function parseChatText(input: string): Segment[] {
  return MARKDOWN.reduce(
    (segments, [pattern, mark]) => segments.flatMap(s => splitMarkdown(s, pattern, mark)),
    parseLegacy(input),
  );
}

export function segmentClasses(segment: Segment): string {
  return [
    segment.color,
    segment.bold && 'cc-bold',
    segment.italic && 'cc-italic',
    segment.underline && 'cc-underline',
    segment.strike && 'cc-strike',
  ]
    .filter(Boolean)
    .join(' ');
}
