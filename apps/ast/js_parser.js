// js_parser.js
const acorn = require("./asset/node_modules/acorn");
const ts = require("./asset/node_modules/typescript");

process.stdin.on('data', (data) => {
    try {
        const code = data.toString();

        // Tentar detectar se é TypeScript ou JavaScript
        const isTypeScript = detectTypeScript(code);

        let ast;
        if (isTypeScript) {
            // Usar TypeScript parser
            const sourceFile = ts.createSourceFile(
                'temp.ts',
                code,
                ts.ScriptTarget.Latest,
                true
            );
            ast = convertTSNodeToJSON(sourceFile);
        } else {
            // Usar Acorn para JavaScript puro
            ast = acorn.parse(code, { ecmaVersion: 'latest' });
        }

        process.stdout.write(JSON.stringify({
            parser: isTypeScript ? 'typescript' : 'javascript',
            ast: ast
        }));
    } catch (error) {
        process.stdout.write(JSON.stringify({ error: error.message }));
    }
    process.exit(0);
});

function detectTypeScript(code) {
    // Detectar sintaxes específicas do TypeScript
    const tsPatterns = [
        /:\s*\w+(\[\])?(\s*\|\s*\w+)*\s*[=;,\)]/,  // Type annotations
        /interface\s+\w+/,                          // Interface declarations
        /type\s+\w+\s*=/,                          // Type aliases
        /enum\s+\w+/,                              // Enum declarations
        /<\w+>/,                                   // Generic syntax
        /as\s+\w+/,                               // Type assertions
        /public|private|protected\s+/,             // Access modifiers
        /readonly\s+/                              // Readonly modifier
    ];

    return tsPatterns.some(pattern => pattern.test(code));
}

function convertTSNodeToJSON(node) {
    if (!node) return null;

    const result = {
        kind: ts.SyntaxKind[node.kind],
        kindNumber: node.kind,
        pos: node.pos,
        end: node.end
    };

    // Adicionar texto se existir
    if (node.text !== undefined) {
        result.text = node.text;
    }

    // Adicionar propriedades específicas baseadas no tipo do nó
    switch (node.kind) {
        case ts.SyntaxKind.Identifier:
            if (node.escapedText) {
                result.name = node.escapedText.toString();
            }
            break;

        case ts.SyntaxKind.StringLiteral:
        case ts.SyntaxKind.NumericLiteral:
        case ts.SyntaxKind.BigIntLiteral:
            result.value = node.text;
            break;

        case ts.SyntaxKind.PropertyAccessExpression:
            result.expression = convertTSNodeToJSON(node.expression);
            result.name = convertTSNodeToJSON(node.name);
            break;

        case ts.SyntaxKind.CallExpression:
            result.expression = convertTSNodeToJSON(node.expression);
            result.arguments = node.arguments ? node.arguments.map(convertTSNodeToJSON) : [];
            break;

        case ts.SyntaxKind.VariableDeclaration:
            if (node.name) result.name = convertTSNodeToJSON(node.name);
            if (node.type) result.type = convertTSNodeToJSON(node.type);
            if (node.initializer) result.initializer = convertTSNodeToJSON(node.initializer);
            break;

        case ts.SyntaxKind.FunctionDeclaration:
        case ts.SyntaxKind.MethodDeclaration:
            if (node.name) result.name = convertTSNodeToJSON(node.name);
            if (node.parameters) result.parameters = node.parameters.map(convertTSNodeToJSON);
            if (node.type) result.returnType = convertTSNodeToJSON(node.type);
            if (node.body) result.body = convertTSNodeToJSON(node.body);
            break;

        case ts.SyntaxKind.InterfaceDeclaration:
            if (node.name) result.name = convertTSNodeToJSON(node.name);
            if (node.members) result.members = node.members.map(convertTSNodeToJSON);
            break;

        case ts.SyntaxKind.PropertySignature:
            if (node.name) result.name = convertTSNodeToJSON(node.name);
            if (node.type) result.type = convertTSNodeToJSON(node.type);
            break;
    }

    // Adicionar modificadores se existirem
    if (node.modifiers && node.modifiers.length > 0) {
        result.modifiers = node.modifiers.map(modifier => ({
            kind: ts.SyntaxKind[modifier.kind],
            kindNumber: modifier.kind
        }));
    }

    // Recursivamente converter todos os filhos
    const children = [];
    ts.forEachChild(node, (child) => {
        const childNode = convertTSNodeToJSON(child);
        if (childNode) {
            children.push(childNode);
        }
    });

    if (children.length > 0) {
        result.children = children;
    }

    return result;
}
