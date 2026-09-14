#!/usr/bin/env node
/**
 * watermark.js — Copyright Watermarking Tool
 * Aplica marcas d'água de autoria em projetos Node.js + Flutter + Go + PHP + HTML/CSS
 *
 * Uso: node watermark.js [--verify] [--remove]
 */

const fs     = require("fs");
const path   = require("path");
const crypto = require("crypto");

// ─────────────────────────────────────────────
//  CONFIGURAÇÃO — edite esta seção
// ─────────────────────────────────────────────
const CONFIG = {
  author:      "Davi Borges",
  email:       "daviborges.sistemas@gmail.com",
  year:        new Date().getFullYear(),
  website:     "",
  projectName: "Beatspan",

  // Caminhos relativos à raiz do projeto
  // backendPath:  "./backend",    // Node.js — não se aplica (projeto so tem o front Flutter)
  frontendPath: ".",   // Flutter — lib/ esta na raiz do repo, nao em frontend/lib
  // goPath:       "./go-service", // Go — não se aplica
  // phpPath:      "./php-app",    // PHP — não se aplica
  // webPath:      "./web",        // HTML/CSS/SCSS — não se aplica

  // Pastas ignoradas
  skipDirs: [
    "node_modules", ".git", ".dart_tool", "build", "vendor",
    ".pub-cache", "coverage", "dist", ".next", "out", "cache",
  ],
};

// ─────────────────────────────────────────────
//  FINGERPRINT
// ─────────────────────────────────────────────
const FINGERPRINT = crypto
  .createHash("sha256")
  .update(`${CONFIG.author}|${CONFIG.email}|${CONFIG.projectName}`)
  .digest("hex");

const TOKEN = FINGERPRINT.substring(0, 16).toUpperCase();
const SIGNATURE_MARKER = `@wm:${TOKEN}`;

// ─────────────────────────────────────────────
//  TEMPLATES DE CABEÇALHO por linguagem
// ─────────────────────────────────────────────

// JS / TS — bloco /** */
function jsHeader() {
  return (
    `/**\n` +
    ` * @copyright © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    ` * @author    ${CONFIG.author}\n` +
    ` * @project   ${CONFIG.projectName}\n` +
    ` * @website   ${CONFIG.website}\n` +
    ` * @token     ${TOKEN}\n` +
    ` * ${SIGNATURE_MARKER}\n` +
    ` *\n` +
    ` * Todos os direitos reservados.\n` +
    ` */\n\n`
  );
}

// Dart — linhas //
function dartHeader() {
  return (
    `// © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    `// Projeto : ${CONFIG.projectName}\n` +
    `// Website : ${CONFIG.website}\n` +
    `// Token   : ${TOKEN}\n` +
    `// ${SIGNATURE_MARKER}\n` +
    `//\n` +
    `// Todos os direitos reservados.\n\n`
  );
}

// Go — linhas // (ANTES do package declaration)
// Em Go, comentários de copyright ficam antes do `package`
function goHeader() {
  return (
    `// © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    `// Projeto : ${CONFIG.projectName}\n` +
    `// Website : ${CONFIG.website}\n` +
    `// Token   : ${TOKEN}\n` +
    `// ${SIGNATURE_MARKER}\n` +
    `//\n` +
    `// Todos os direitos reservados.\n\n`
  );
}

// PHP — bloco /** */ inserido após <?php
function phpHeader() {
  return (
    `\n/**\n` +
    ` * @copyright © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    ` * @author    ${CONFIG.author}\n` +
    ` * @project   ${CONFIG.projectName}\n` +
    ` * @website   ${CONFIG.website}\n` +
    ` * @token     ${TOKEN}\n` +
    ` * ${SIGNATURE_MARKER}\n` +
    ` *\n` +
    ` * Todos os direitos reservados.\n` +
    ` */\n\n`
  );
}

// HTML — comentário <!-- -->
function htmlHeader() {
  return (
    `<!--\n` +
    `  © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    `  Projeto : ${CONFIG.projectName}\n` +
    `  Website : ${CONFIG.website}\n` +
    `  Token   : ${TOKEN}\n` +
    `  ${SIGNATURE_MARKER}\n` +
    `  Todos os direitos reservados.\n` +
    `-->\n`
  );
}

// CSS / SCSS / SASS — bloco /* */
function cssHeader() {
  return (
    `/**\n` +
    ` * © ${CONFIG.year} ${CONFIG.author} <${CONFIG.email}>\n` +
    ` * Projeto : ${CONFIG.projectName}\n` +
    ` * Website : ${CONFIG.website}\n` +
    ` * Token   : ${TOKEN}\n` +
    ` * ${SIGNATURE_MARKER}\n` +
    ` *\n` +
    ` * Todos os direitos reservados.\n` +
    ` */\n\n`
  );
}

// ─────────────────────────────────────────────
//  MÓDULOS DE ASSINATURA CENTRALIZADOS
// ─────────────────────────────────────────────
function jsSignatureModule() {
  return `// ${SIGNATURE_MARKER} — NÃO REMOVA
const _COPYRIGHT = Object.freeze({
  author:      "${CONFIG.author}",
  email:       "${CONFIG.email}",
  project:     "${CONFIG.projectName}",
  year:        ${CONFIG.year},
  token:       "${TOKEN}",
  fingerprint: "${FINGERPRINT}",
  verify() {
    const crypto = require("crypto");
    const expected = crypto
      .createHash("sha256")
      .update(\`\${this.author}|\${this.email}|\${this.project}\`)
      .digest("hex");
    return expected === this.fingerprint;
  },
});
module.exports = { _COPYRIGHT };
`;
}

function dartSignatureFile() {
  return `// ${SIGNATURE_MARKER} — NÃO REMOVA
// © ${CONFIG.year} ${CONFIG.author}

/// Metadados de autoria embutidos no build. Não remova.
class AppCopyright {
  AppCopyright._();
  static const String author      = '${CONFIG.author}';
  static const String email       = '${CONFIG.email}';
  static const String project     = '${CONFIG.projectName}';
  static const int    year        = ${CONFIG.year};
  static const String token       = '${TOKEN}';
  static const String fingerprint = '${FINGERPRINT}';
  static bool get isAuthentic =>
      fingerprint.startsWith(token.toLowerCase()) && fingerprint.length == 64;
}
`;
}

// Go: arquivo copyright.go com constante embutida
function goSignatureFile(packageName) {
  return `// ${SIGNATURE_MARKER} — NÃO REMOVA
// © ${CONFIG.year} ${CONFIG.author}

package ${packageName || "main"}

// Copyright contém os metadados de autoria embutidos no binário.
var Copyright = struct {
\tAuthor      string
\tEmail       string
\tProject     string
\tYear        int
\tToken       string
\tFingerprint string
}{
\tAuthor:      "${CONFIG.author}",
\tEmail:       "${CONFIG.email}",
\tProject:     "${CONFIG.projectName}",
\tYear:        ${CONFIG.year},
\tToken:       "${TOKEN}",
\tFingerprint: "${FINGERPRINT}",
}
`;
}

// PHP: arquivo _copyright.php
function phpSignatureFile() {
  return `<?php
// ${SIGNATURE_MARKER} — NÃO REMOVA
// © ${CONFIG.year} ${CONFIG.author}

/**
 * Metadados de autoria embutidos na aplicação. Não remova.
 */
final class AppCopyright {
    private function __construct() {}

    public const AUTHOR      = '${CONFIG.author}';
    public const EMAIL       = '${CONFIG.email}';
    public const PROJECT     = '${CONFIG.projectName}';
    public const YEAR        = ${CONFIG.year};
    public const TOKEN       = '${TOKEN}';
    public const FINGERPRINT = '${FINGERPRINT}';

    public static function isAuthentic(): bool {
        $expected = hash('sha256', self::AUTHOR . '|' . self::EMAIL . '|' . self::PROJECT);
        return $expected === self::FINGERPRINT;
    }
}
`;
}

// ─────────────────────────────────────────────
//  UTILITÁRIOS
// ─────────────────────────────────────────────
function getAllFiles(dir, extensions) {
  if (!dir || !fs.existsSync(dir)) return [];
  const results = [];
  function walk(current) {
    for (const entry of fs.readdirSync(current)) {
      if (CONFIG.skipDirs.includes(entry)) continue;
      const full = path.join(current, entry);
      const stat = fs.statSync(full);
      if (stat.isDirectory()) walk(full);
      else if (extensions.some((ext) => entry.endsWith(ext))) results.push(full);
    }
  }
  walk(dir);
  return results;
}

function alreadyWatermarked(content) {
  return content.includes(SIGNATURE_MARKER);
}

// Adiciona cabeçalho genérico (preserva shebang)
function addHeader(filePath, header) {
  let content = fs.readFileSync(filePath, "utf8");
  if (alreadyWatermarked(content)) return false;
  if (content.startsWith("#!")) {
    const nl = content.indexOf("\n");
    content = content.substring(0, nl + 1) + "\n" + header + content.substring(nl + 1);
  } else {
    content = header + content;
  }
  fs.writeFileSync(filePath, content, "utf8");
  return true;
}

// PHP: cabeçalho vai APÓS a tag <?php de abertura
function addPHPHeader(filePath) {
  let content = fs.readFileSync(filePath, "utf8");
  if (alreadyWatermarked(content)) return false;
  const phpTag = content.match(/^<\?php(\r?\n)?/i);
  if (!phpTag) { content = "<?php\n" + phpHeader() + content; }
  else { content = phpTag[0] + phpHeader() + content.substring(phpTag[0].length); }
  fs.writeFileSync(filePath, content, "utf8");
  return true;
}

// HTML: cabeçalho vai APÓS <!DOCTYPE html> se existir, senão no topo
function addHTMLHeader(filePath) {
  let content = fs.readFileSync(filePath, "utf8");
  if (alreadyWatermarked(content)) return false;
  const doctype = content.match(/<!DOCTYPE[^>]*>\s*/i);
  if (doctype) {
    content = doctype[0] + htmlHeader() + content.substring(doctype[0].length);
  } else {
    content = htmlHeader() + content;
  }
  fs.writeFileSync(filePath, content, "utf8");
  return true;
}

function removeHeader(filePath) {
  let content = fs.readFileSync(filePath, "utf8");
  if (!content.includes(SIGNATURE_MARKER)) return false;
  // Remove blocos /** ... @wm ... */
  content = content.replace(/\/\*\*[\s\S]*?@wm:[A-F0-9]+[\s\S]*?\*\/\n\n?/g, "");
  // Remove blocos <!-- ... @wm ... -->
  content = content.replace(/<!--[\s\S]*?@wm:[A-F0-9]+[\s\S]*?-->\n?/g, "");
  // Remove linhas de comentário // consecutivas com @wm
  content = content.replace(/(\/\/ .*\n)*\/\/ @wm:[A-F0-9]+\n(\/\/.*\n)*\n?/g, "");
  fs.writeFileSync(filePath, content, "utf8");
  return true;
}

// ─────────────────────────────────────────────
//  ESTEGANOGRAFIA EM PNG (chunk tEXt — sem deps)
// ─────────────────────────────────────────────
function embedInPNG(filePath, message) {
  const buf = fs.readFileSync(filePath);
  const PNG_SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!buf.slice(0, 8).equals(PNG_SIG)) throw new Error("PNG inválido");

  const keyword = Buffer.from("Copyright\0");
  const data    = Buffer.concat([keyword, Buffer.from(message, "utf8")]);
  const type    = Buffer.from("tEXt");
  const len     = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);

  function crc32(b) {
    const t = new Uint32Array(256);
    for (let i = 0; i < 256; i++) { let c = i; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[i] = c; }
    let crc = 0xffffffff;
    for (let i = 0; i < b.length; i++) crc = (crc >>> 8) ^ t[(crc ^ b[i]) & 0xff];
    return (crc ^ 0xffffffff) >>> 0;
  }

  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([type, data])), 0);
  const chunk  = Buffer.concat([len, type, data, crcBuf]);
  const output = Buffer.concat([buf.slice(0, 33), chunk, buf.slice(33)]);
  fs.writeFileSync(filePath, output);
  return true;
}

function readFromPNG(filePath) {
  const buf = fs.readFileSync(filePath);
  let offset = 8; const msgs = [];
  while (offset < buf.length - 4) {
    const length = buf.readUInt32BE(offset);
    const type   = buf.slice(offset + 4, offset + 8).toString("ascii");
    if (type === "tEXt") {
      const d = buf.slice(offset + 8, offset + 8 + length);
      const ni = d.indexOf(0);
      if (ni !== -1) msgs.push({ keyword: d.slice(0, ni).toString(), value: d.slice(ni + 1).toString("utf8") });
    }
    if (type === "IEND") break;
    offset += 12 + length;
  }
  return msgs;
}

// ─────────────────────────────────────────────
//  PROCESSADORES POR LINGUAGEM
// ─────────────────────────────────────────────
function processLang({ label, dir, extensions, headerFn, addFn }) {
  if (!dir) return 0;
  log("cyan", "→", `Processando ${label}...`);
  const files = getAllFiles(dir, extensions);
  let count = 0;
  for (const f of files) {
    const marked = addFn
      ? addFn(f)
      : addHeader(f, headerFn());
    if (marked) { log("green", "  ✓", path.relative(".", f)); count++; }
  }
  log("dim", "  ", `${count}/${files.length} arquivos marcados\n`);
  return count;
}

// ─────────────────────────────────────────────
//  MÓDULOS DE ASSINATURA
// ─────────────────────────────────────────────
function generateSignatureFiles() {
  log("cyan", "→", "Gerando módulos de assinatura...");

  const write = (p, content) => {
    if (fs.existsSync(p)) return;
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, content, "utf8");
    log("green", "  ✓", path.relative(".", p));
  };

  if (CONFIG.backendPath)  write(path.join(CONFIG.backendPath, "_copyright.js"),         jsSignatureModule());
  if (CONFIG.frontendPath) write(path.join(CONFIG.frontendPath, "lib", "_copyright.dart"), dartSignatureFile());

  // Go: detecta o nome do pacote no main.go ou usa "main"
  if (CONFIG.goPath) {
    const mainGo = path.join(CONFIG.goPath, "main.go");
    let pkg = "main";
    if (fs.existsSync(mainGo)) {
      const m = fs.readFileSync(mainGo, "utf8").match(/^package\s+(\w+)/m);
      if (m) pkg = m[1];
    }
    write(path.join(CONFIG.goPath, "copyright.go"), goSignatureFile(pkg));
  }

  if (CONFIG.phpPath) write(path.join(CONFIG.phpPath, "_copyright.php"), phpSignatureFile());
}

// ─────────────────────────────────────────────
//  ARQUIVO .copyright
// ─────────────────────────────────────────────
function generateCopyrightFile() {
  const sig = {
    author:      CONFIG.author,
    email:       CONFIG.email,
    project:     CONFIG.projectName,
    year:        CONFIG.year,
    website:     CONFIG.website,
    token:       TOKEN,
    fingerprint: FINGERPRINT,
    createdAt:   new Date().toISOString(),
    proof: crypto.createHash("sha256").update(FINGERPRINT + TOKEN + CONFIG.email).digest("hex"),
  };
  fs.writeFileSync(".copyright", JSON.stringify(sig, null, 2) + "\n", "utf8");
  log("green", "✓", ".copyright gerado");
}

// ─────────────────────────────────────────────
//  PIPELINE PRINCIPAL
// ─────────────────────────────────────────────
function applyWatermarks() {
  log("cyan", "\n🔐", "Iniciando watermarking...\n");
  log("dim", "  ", `Autor      : ${CONFIG.author}`);
  log("dim", "  ", `Token      : ${TOKEN}`);
  log("dim", "  ", `Fingerprint: ${FINGERPRINT.substring(0, 32)}...\n`);

  let total = 0;

  // Node.js — JS/TS
  total += processLang({
    label: "Node.js (JS/TS)",
    dir: CONFIG.backendPath,
    extensions: [".js", ".ts", ".mjs", ".cjs"],
    headerFn: jsHeader,
  });

  // Flutter — Dart
  total += processLang({
    label: "Flutter (Dart)",
    dir: CONFIG.frontendPath ? path.join(CONFIG.frontendPath, "lib") : null,
    extensions: [".dart"],
    headerFn: dartHeader,
  });

  // Go
  total += processLang({
    label: "Go",
    dir: CONFIG.goPath,
    extensions: [".go"],
    headerFn: goHeader,
  });

  // PHP
  total += processLang({
    label: "PHP",
    dir: CONFIG.phpPath,
    extensions: [".php"],
    addFn: (f) => addPHPHeader(f),
  });

  // HTML
  total += processLang({
    label: "HTML",
    dir: CONFIG.webPath,
    extensions: [".html", ".htm"],
    addFn: (f) => addHTMLHeader(f),
  });

  // CSS / SCSS / SASS
  total += processLang({
    label: "CSS/SCSS/SASS",
    dir: CONFIG.webPath,
    extensions: [".css", ".scss", ".sass"],
    headerFn: cssHeader,
  });

  // Módulos de assinatura
  generateSignatureFiles();

  // PNGs
  log("cyan", "\n→", "Buscando assets PNG para esteganografia...");
  const pngDirs = [
    CONFIG.frontendPath && path.join(CONFIG.frontendPath, "assets"),
    CONFIG.frontendPath && path.join(CONFIG.frontendPath, "images"),
    CONFIG.backendPath  && path.join(CONFIG.backendPath, "public"),
    CONFIG.webPath      && path.join(CONFIG.webPath, "images"),
    CONFIG.webPath      && path.join(CONFIG.webPath, "assets"),
    CONFIG.phpPath      && path.join(CONFIG.phpPath, "public"),
  ].filter(Boolean);

  const pngMsg = `© ${CONFIG.year} ${CONFIG.author} | ${CONFIG.email} | token:${TOKEN}`;
  let pngCount = 0;

  for (const dir of pngDirs) {
    if (!fs.existsSync(dir)) continue;
    for (const png of getAllFiles(dir, [".png"])) {
      try {
        embedInPNG(png, pngMsg);
        log("green", "  ✓", `PNG: ${path.relative(".", png)}`);
        pngCount++;
      } catch (e) {
        log("yellow", "  ⚠", `Ignorado: ${path.relative(".", png)} — ${e.message}`);
      }
    }
  }
  if (pngCount === 0) log("dim", "  ", "Nenhum PNG encontrado nos diretórios de assets");

  // .copyright
  log("cyan", "\n→", "Gerando arquivo de evidência...");
  generateCopyrightFile();

  log("green", "\n✅", `Concluído! ${total} arquivos marcados, ${pngCount} PNGs processados.`);
  log("yellow", "\n📋", "Fingerprint completo:");
  log("dim",    "   ", FINGERPRINT);
  log("dim",    "   ", "(salvo em .copyright)\n");
}

// ─────────────────────────────────────────────
//  VERIFICAÇÃO
// ─────────────────────────────────────────────
function verifyWatermarks() {
  log("cyan", "\n🔍", "Verificando marcas d'água...\n");
  let ok = 0, missing = 0;

  const check = (files, label) => {
    for (const f of files) {
      const content = fs.readFileSync(f, "utf8");
      if (alreadyWatermarked(content)) { log("green", "  ✓", `${label}: ${path.relative(".", f)}`); ok++; }
      else { log("red", "  ✗", `${label}: ${path.relative(".", f)} — SEM MARCA`); missing++; }
    }
  };

  check(getAllFiles(CONFIG.backendPath, [".js",".ts",".mjs",".cjs"]), "JS");
  check(getAllFiles(CONFIG.frontendPath ? path.join(CONFIG.frontendPath,"lib") : null, [".dart"]), "Dart");
  check(getAllFiles(CONFIG.goPath,  [".go"]),  "Go");
  check(getAllFiles(CONFIG.phpPath, [".php"]), "PHP");
  check(getAllFiles(CONFIG.webPath, [".html",".htm",".css",".scss",".sass"]), "Web");

  if (fs.existsSync(".copyright")) {
    const data  = JSON.parse(fs.readFileSync(".copyright", "utf8"));
    const valid = data.fingerprint === FINGERPRINT && data.token === TOKEN;
    log(valid ? "green" : "red", valid ? "  ✓" : "  ✗", `.copyright — ${valid ? "válido" : "INVÁLIDO"}`);
  } else {
    log("red", "  ✗", ".copyright não encontrado");
  }

  log(ok > 0 ? "green" : "red", "\n📊", `${ok} marcados | ${missing} sem marca`);
}

// ─────────────────────────────────────────────
//  REMOÇÃO
// ─────────────────────────────────────────────
function removeWatermarks() {
  log("yellow", "\n⚠️ ", "Removendo marcas d'água...\n");
  const all = [
    ...getAllFiles(CONFIG.backendPath, [".js",".ts",".mjs",".cjs"]),
    ...getAllFiles(CONFIG.frontendPath ? path.join(CONFIG.frontendPath,"lib") : null, [".dart"]),
    ...getAllFiles(CONFIG.goPath,  [".go"]),
    ...getAllFiles(CONFIG.phpPath, [".php"]),
    ...getAllFiles(CONFIG.webPath, [".html",".htm",".css",".scss",".sass"]),
  ];
  let count = 0;
  for (const f of all) {
    if (removeHeader(f)) { log("yellow", "  ~", path.relative(".", f)); count++; }
  }
  log("yellow", "\n~", `${count} arquivos desmarcados`);
}

// ─────────────────────────────────────────────
//  LOG COLORIDO
// ─────────────────────────────────────────────
const COLORS = { red:"\x1b[31m", green:"\x1b[32m", yellow:"\x1b[33m", cyan:"\x1b[36m", dim:"\x1b[2m", reset:"\x1b[0m" };
function log(color, prefix, msg) { console.log(`${COLORS[color]||""}${prefix} ${msg}${COLORS.reset}`); }

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
const args = process.argv.slice(2);
if      (args.includes("--verify")) verifyWatermarks();
else if (args.includes("--remove")) removeWatermarks();
else                                applyWatermarks();
