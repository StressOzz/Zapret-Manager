// Run: node tests/legacy-bypass.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../ZapretManager_LuCI.sh'), 'utf8');
const helper = source.match(/function legacy_bypass_info\(c\) \{[\s\S]*?\n\}/)[0];
const context = {
  CFG: 'netshift', BYPASS: 'zm_bypass',
  s: value => value == null ? '' : String(value),
  push: (array, value) => array.push(value),
  rawlist: value => value == null ? [] : Array.isArray(value) ? value : [value],
  uniq: values => [...new Set(values)],
  sec_label: section => section.zm_label || section['.name'],
  domain_lines: section => section.domains || [],
  subnet_lines: section => section.subnets || [],
};
vm.createContext(context);
vm.runInContext(helper, context);
const sections = [
  { '.name': 'main', connection_type: 'proxy' },
  { '.name': 'vpn', connection_type: 'vpn' },
  { '.name': 'zm_bypass', connection_type: 'exclusion' },
  { '.name': 'p2p', connection_type: 'exclusion', domains: ['tracker.example'],
    subnets: ['192.0.2.0/24'], local_domain_lists: ['/etc/netshift/local.lst'],
    local_subnet_lists: ['/etc/netshift/local.lst'], remote_domain_lists: ['https://example.com/domains.lst'],
    community_lists: ['example'] },
  { '.name': 'old', zm_label: 'Disabled exclusion', connection_type: 'exclusion', disabled: '1' },
  { '.name': 'dns', connection_type: 'dns' },
];
const before = JSON.stringify(sections);
const cursor = { foreach(config, type, callback) {
  assert.equal(config, 'netshift');
  assert.equal(type, 'section');
  sections.forEach(callback);
} };
const result = JSON.parse(JSON.stringify(context.legacy_bypass_info(cursor)));
assert.deepEqual(result, [
  { name: 'p2p', label: 'p2p', enabled: true, domains: ['tracker.example'],
    subnets: ['192.0.2.0/24'], community: ['example'],
    lists: ['/etc/netshift/local.lst', 'https://example.com/domains.lst'] },
  { name: 'old', label: 'Disabled exclusion', enabled: false,
    domains: [], subnets: [], community: [], lists: [] },
]);
assert.equal(JSON.stringify(sections), before, 'Reading must not change the configuration');
assert.equal(context.legacy_bypass_info({ foreach() {} }).length, 0);
assert.match(source, /legacy_bypass: legacy_bypass_info\(c\)/);
assert.match(source, /cfg && cfg\.legacy_bypass/);
const pageStart = source.lastIndexOf('cat > ', source.indexOf('function renderByp()'));
const page = source.slice(source.indexOf('\n', pageStart) + 1).split(/\r?\nZM_INSTALLER_EOF/)[0];
new vm.Script('(function() {\n' + page + '\n})'); // LuCI loads views as functions.
console.log('Legacy exclusion visibility checks passed');
