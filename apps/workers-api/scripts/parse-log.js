const fs = require('fs');
const content = fs.readFileSync('C:/Users/prise/.gemini/antigravity-ide/brain/8aa0215b-9c8b-4fc7-9aaa-850909fdfcbb/.system_generated/tasks/task-642.log', 'utf8');
const urls = [];
const re = /"url":\s*"([^"]+)"/g;
let match;
while ((match = re.exec(content)) !== null) {
  urls.push(match[1]);
}
console.log('Total URLs found:', urls.length);
console.log('Last 20 URLs:');
urls.slice(-20).forEach(u => console.log(' ->', u));
