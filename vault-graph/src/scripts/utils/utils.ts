import fs from 'fs';

// write content to a file
export function writeStringToFile(stringContent: string, filename: string): void {
  fs.writeFileSync(filename, stringContent, 'utf8');
  console.log(`File written to ${filename}`);
}

// delay for a specified time in ms
export function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}
