(function() {
    const CONFIG = {
        MESSAGES: [
            "🚨 ВНИМАНИЕ! АДМИНЫ ЭТОГО ЧАТА - МОШЕННИКИ! 🚨 {LINK}",
            "ЗДЕСЬ ОБМАН! НЕ ВЕДИТЕСЬ НА ИХ СХЕМЫ! {LINK}",
            "ЭТОТ ЧАТ БУДЕТ ЗАБЛОКИРОВАН ЗА МОШЕННИЧЕСТВО! {LINK}",
            "ВСЕ ДОКАЗАТЕЛЬСТВА ЗДЕСЬ: {LINK}",
            "🚫 SCAM ALERT! THIS CHAT WILL BE REPORTED! {LINK}"
        ],
        LINK: "https://t.me/biosQper", 
        SUM: "50,000",
        BOMB_COUNT: 1000,
        DELAY: 10,
        TARGET_ADMINS: true,
        USE_EMOJIS: true,
        USE_CAPS: true
    };

    function generateMessage() {
        let msg = CONFIG.MESSAGES[Math.floor(Math.random() * CONFIG.MESSAGES.length)];
        
        msg = msg.replace(/{LINK}/g, CONFIG.LINK)
                 .replace(/{SUM}/g, CONFIG.SUM);
        
        if (CONFIG.USE_CAPS) {
            const linkPos = msg.indexOf(CONFIG.LINK);
            if (linkPos !== -1) {
                const beforeLink = msg.substring(0, linkPos).toUpperCase();
                const afterLink = msg.substring(linkPos + CONFIG.LINK.length).toUpperCase();
                msg = beforeLink + CONFIG.LINK + afterLink;
            } else {
                msg = msg.toUpperCase();
            }
        }
        
        if (CONFIG.USE_EMOJIS) msg = addEmojis(msg);
        return msg;
    }

    function addEmojis(text) {
        const emojis = ["💢", "🔥", "⚡", "💣", "⚠️", "🚨", "🛑", "⛔", "🔴", "❌"];
        return text.split(' ').map(word => 
            Math.random() > 0.8 ? word + emojis[Math.floor(Math.random() * emojis.length)] : word
        ).join(' ');
    }

    const sendMethods = {
        fastSend() {
            const input = document.querySelector('[contenteditable="true"][data-role="input"]') || 
                          document.querySelector('[contenteditable="true"]');
            if (!input) return false;
            
            input.focus();
            input.innerHTML = '';
            document.execCommand('insertText', false, generateMessage());
            
            const sendBtn = document.querySelector('button[aria-label="Send"], button[aria-label="Отправить"], .btn-send') || 
                           document.querySelector('.composer-btn-send') ||
                           document.querySelector('button:not([aria-label]):not([class])');
            
            if (sendBtn) {
                sendBtn.click();
                return true;
            }
            
            this.simulateEnter();
            return true;
        },
        
        simulateEnter() {
            const event = new KeyboardEvent('keydown', {
                key: 'Enter',
                code: 'Enter',
                keyCode: 13,
                bubbles: true,
                cancelable: true
            });
            document.activeElement.dispatchEvent(event);
        },
        
        targetAdmins() {
            const admins = Array.from(document.querySelectorAll('.user-title, .chat-user, .user-name'));
            admins.forEach(admin => {
                if (admin.textContent.match(/admin|админ|owner|владелец/i)) {
                    admin.click();
                    setTimeout(() => {
                        this.fastSend();
                        history.back();
                    }, 100);
                }
            });
        }
    };

    async function nuclearBomb() {
        console.log('ЗАПУСК...');
        
        let sent = 0;
        const bombInterval = setInterval(() => {
            if (sent >= CONFIG.BOMB_COUNT) {
                clearInterval(bombInterval);
                console.log('ОТПРАВЛЕНО %d СООБЩЕНИЙ!', sent);
                return;
            }
            
            sendMethods.fastSend();
            if (CONFIG.TARGET_ADMINS && sent % 10 === 0) sendMethods.targetAdmins();
            
            sent++;
            if (sent % 100 === 0) console.log('☢️ Отправлено сообщений:', sent);
            
            window.scrollTo(0, document.body.scrollHeight);
        }, CONFIG.DELAY);
    }

    function extraPain() {
        const reportAll = setInterval(() => {
            const menuButtons = document.querySelectorAll('.btn-icon, .chat-actions, .menu-button');
            if (menuButtons.length) {
                menuButtons.forEach(btn => {
                    btn.click();
                    setTimeout(() => {
                        const reportBtn = document.evaluate(
                            "//button[contains(., 'Report') or contains(., 'Пожаловаться')]",
                            document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
                        ).singleNodeValue;
                        if (reportBtn) reportBtn.click();
                    }, 100);
                });
            }
        }, 5000);

        document.body.addEventListener('click', (e) => {
            if (e.target.closest('.chat-user, .user-title, .user-name')) {
                setTimeout(sendMethods.fastSend, 300);
            }
        });
    }

    nuclearBomb();
    extraPain();
})();
