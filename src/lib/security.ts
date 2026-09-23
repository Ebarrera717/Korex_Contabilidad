import crypto from 'crypto';

const DEFAULT_SECRET = 'Korex_Contabilidad_Master_Security_Key_2026_Enterprise_AES';

function getDerivedKey(customSecret?: string): Buffer {
    const secret = customSecret || process.env.ENCRYPTION_KEY || DEFAULT_SECRET;
    return crypto.createHash('sha256').update(secret).digest();
}

/**
 * Encripta un texto plano utilizando AES-256-CBC con vector de inicialización aleatorio (16 bytes).
 * Retorna el token en formato ENC(<iv_hex>:<ciphertext_hex>).
 */
export function encryptPassword(plainText: string, customSecret?: string): string {
    if (!plainText || typeof plainText !== 'string') return plainText;
    const trimmed = plainText.trim();
    if (trimmed === '' || trimmed.startsWith('ENC(')) return plainText;

    try {
        const key = getDerivedKey(customSecret);
        const iv = crypto.randomBytes(16);
        const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
        let encrypted = cipher.update(plainText, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return `ENC(${iv.toString('hex')}:${encrypted})`;
    } catch (err: any) {
        console.error('[SECURITY] Error al encriptar contraseña:', err.message);
        return plainText;
    }
}

/**
 * Desencripta un token ENC(<iv_hex>:<ciphertext_hex>) a texto plano.
 */
export function decryptPassword(cipherText: string, customSecret?: string): string {
    if (!cipherText || typeof cipherText !== 'string') return cipherText;
    const trimmed = cipherText.trim();
    if (!trimmed.startsWith('ENC(') || !trimmed.endsWith(')')) return cipherText;

    try {
        const inner = trimmed.slice(4, -1).trim();
        const parts = inner.split(':');
        if (parts.length !== 2) return cipherText;

        const [ivHex, encHex] = parts;
        if (!ivHex || !encHex) return cipherText;

        const key = getDerivedKey(customSecret);
        const iv = Buffer.from(ivHex, 'hex');
        const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
        let decrypted = decipher.update(encHex, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        return decrypted;
    } catch (err: any) {
        console.warn('[SECURITY] No fue posible desencriptar token, retornando original:', err.message);
        return cipherText;
    }
}

/**
 * Verifica si una cadena contiene el formato encriptado de Korex.
 */
export function isEncrypted(value: string): boolean {
    if (!value || typeof value !== 'string') return false;
    const trimmed = value.trim();
    return trimmed.startsWith('ENC(') && trimmed.endsWith(')') && trimmed.includes(':');
}

/**
 * Reemplaza de manera transparente todos los tokens ENC(...) dentro de una URL o cadena de conexión.
 */
export function decryptUrlPasswords(connectionUrl: string, customSecret?: string): string {
    if (!connectionUrl || typeof connectionUrl !== 'string') return connectionUrl;
    return connectionUrl.replace(/ENC\([a-fA-F0-9]+:[a-fA-F0-9]+\)/g, (match) => {
        return decryptPassword(match, customSecret);
    });
}
