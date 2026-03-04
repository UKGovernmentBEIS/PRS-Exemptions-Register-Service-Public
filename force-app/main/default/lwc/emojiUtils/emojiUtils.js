/**
 * Removes all emojis from a string
 * @param {string} str - The input string
 * @returns {string} - String with all emojis removed
 */
export function removeEmojis(str) {
    if (str === null || str === undefined || str === '') {
        return '';
    }
    
    const stringValue = String(str);

    return stringValue
        .replace(/[#*0-9]\uFE0F?\u20E3/gu, '')
        .replace(/\p{Emoji_Modifier_Base}\p{Emoji_Modifier}?/gu, '')
        .replace(/\p{Emoji_Presentation}/gu, '')
        .replace(/\p{Extended_Pictographic}/gu, '')
        .replace(/[\u200d\ufe0f]/gu, '')
        .replace(/[\u{1f1e6}-\u{1f1ff}]{2}/gu, '')
        .replace(/[\u{E0020}-\u{E007F}]+/gu, '');
}

