// const crypto = require('crypto');

// // Generate private key
// const curve = 'secp256k1';
// const privateKey = crypto.generateKeyPairSync(curve, {
//   privateKeyEncoding: {
//     type: 'pkcs8',
//     format: 'pem'
//   }
// }).privateKey;

// // Encrypt private key
// const password = 'mysecretpassword';
// const salt = crypto.randomBytes(16);
// const iterations = 100000;
// const keylen = 32;
// const digest = 'sha256';
// const encryption = 'aes-256-cbc';

// const key = crypto.scryptSync(password, salt, keylen, { N: iterations, r: 8, p: 1 });
// const iv = crypto.randomBytes(16);
// const cipher = crypto.createCipheriv(encryption, key, iv);

// let encryptedPrivateKey = cipher.update(privateKey, 'utf8', 'base64');
// encryptedPrivateKey += cipher.final('base64');

// console.log('Encrypted private key:', encryptedPrivateKey);

// // Decrypt private key
// const decipher = crypto.createDecipheriv(encryption, key, iv);
// let decryptedPrivateKey = decipher.update(encryptedPrivateKey, 'base64', 'utf8');
// decryptedPrivateKey += decipher.final('utf8');

// console.log('Decrypted private key:', decryptedPrivateKey);

// // Compare the original private key with the decrypted one
// console.log('Match:', privateKey === decryptedPrivateKey);
