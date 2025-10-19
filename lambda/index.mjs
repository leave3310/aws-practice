import https from 'https';

function formatBytes(fileSize) {
    if (fileSize === 0) return '0 Bytes';
    let unitIndex = 0;
    const units = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    let returnSize = fileSize;

    while (returnSize >= 1024) {
        returnSize /= 1024;
        unitIndex++;
    }
    return `${returnSize.toFixed(2)} ${units[unitIndex]}`;
}

function sendDiscordNotification(data, options) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, (res) => {
            // If the status code is good (e.g., 204 No Content), it worked.
            if (res.statusCode >= 200 && res.statusCode < 300) {
                resolve(); // Signal that the promise was successful
            } else {
                reject(new Error(`Request failed with status: ${res.statusCode}`));
            }
        });

        req.on('error', (e) => {
            reject(e); // Handle network errors
        });

        // Write our JSON data to the request body
        req.write(data);
        // Finalize the request
        req.end();
    });
}

export const handler = async (event) => {
    try {
        // 從 S3 事件中解析出需要的資訊
        console.log(JSON.parse(JSON.stringify(event)));
        
        const record = event.Records[0];
        const bucketName = record.s3.bucket.name;
        // 解碼檔名以處理特殊字元
        const fileName = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
        const fileSizeInBytes = record.s3.object.size;
        const uploadTime = record.eventTime;

        // 準備要發送到 Discord 的訊息
        const formattedSize = formatBytes(fileSizeInBytes);
        const message = `會計部注意！有新的單據上傳：\n\n
        **檔名**: \`${fileName}\`\n
        **大小**: ${formattedSize}\n
        **上傳時間**: ${uploadTime}\n
        **儲存桶**: ${bucketName}`;

        const data = JSON.stringify({ content: message });

        // 準備請求選項 (Webhook URL 建議放在環境變數中)
        // 我們稍後會在 AWS 設定中處理 DISCORD_WEBHOOK_URL
        const webhookUrl = new URL(process.env.DISCORD_WEBHOOK_URL);
        const options = {
            hostname: webhookUrl.hostname,
            path: webhookUrl.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        };

        // 發送通知
        await sendDiscordNotification(data, options);
        console.log('Successfully sent notification.');

        return { statusCode: 200, body: 'Success!' };

    } catch (error) {
        console.error('Error processing S3 event:', error);
        return { statusCode: 500, body: 'Failed to process event.' };
    }
};

