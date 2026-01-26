// enɳoté Web App
// Desktop note preparation for iOS app

(function() {
    'use strict';

    // DOM Elements
    const notesInput = document.getElementById('notes-input');
    const noteCount = document.getElementById('count');
    const createStackBtn = document.getElementById('create-stack');
    const inputSection = document.getElementById('input-section');
    const qrSection = document.getElementById('qr-section');
    const qrCanvas = document.getElementById('qr-canvas');
    const countdown = document.getElementById('countdown');
    const timerProgress = document.getElementById('timer-progress');
    const newStackBtn = document.getElementById('new-stack');

    // Constants
    const EXPIRY_MINUTES = 5;
    const STACK_ID_LENGTH = 12;

    // State
    let countdownInterval = null;
    let expiryTime = null;

    // Generate random alphanumeric ID
    function generateStackId() {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < STACK_ID_LENGTH; i++) {
            result += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return result;
    }

    // Parse notes from textarea
    function parseNotes() {
        const text = notesInput.value.trim();
        if (!text) return [];

        return text
            .split('\n')
            .map(line => line.trim())
            .filter(line => line.length > 0);
    }

    // Update note count display
    function updateNoteCount() {
        const notes = parseNotes();
        noteCount.textContent = notes.length;
        createStackBtn.disabled = notes.length === 0;
    }

    // Format time as M:SS
    function formatTime(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    // Update countdown timer
    function updateCountdown() {
        const now = Date.now();
        const remaining = Math.max(0, Math.ceil((expiryTime - now) / 1000));
        const totalSeconds = EXPIRY_MINUTES * 60;
        const progress = (remaining / totalSeconds) * 100;

        countdown.textContent = formatTime(remaining);
        timerProgress.style.width = `${progress}%`;

        // Update color based on time remaining
        timerProgress.classList.remove('warning', 'critical');
        if (remaining <= 60) {
            timerProgress.classList.add('critical');
        } else if (remaining <= 120) {
            timerProgress.classList.add('warning');
        }

        // Expired
        if (remaining <= 0) {
            clearInterval(countdownInterval);
            resetToInput();
        }
    }

    // Create stack and show QR
    async function createStack() {
        const notes = parseNotes();
        if (notes.length === 0) return;

        const stackId = generateStackId();
        const now = new Date();
        const expiresAt = new Date(now.getTime() + EXPIRY_MINUTES * 60 * 1000);

        // Stack object (for CloudKit integration)
        const stack = {
            id: stackId,
            notes: notes,
            createdAt: now.toISOString(),
            expiresAt: expiresAt.toISOString(),
            fetched: false
        };

        // TODO: CloudKit Integration
        // When CloudKit is configured, uncomment and implement:
        // await saveToCloudKit(stack);

        // For now, log the stack data
        console.log('Stack created:', stack);

        // Generate QR code with deep link
        const deepLink = `ennote://stack/${stackId}`;

        try {
            await QRCode.toCanvas(qrCanvas, deepLink, {
                width: 200,
                margin: 0,
                color: {
                    dark: '#171717',
                    light: '#FFFFFF'
                },
                errorCorrectionLevel: 'M'
            });

            // Show QR section
            inputSection.classList.add('hidden');
            qrSection.classList.remove('hidden');

            // Start countdown
            expiryTime = expiresAt.getTime();
            updateCountdown();
            countdownInterval = setInterval(updateCountdown, 1000);

        } catch (err) {
            console.error('QR generation failed:', err);
            alert('Failed to generate QR code. Please try again.');
        }
    }

    // Reset to input view
    function resetToInput() {
        if (countdownInterval) {
            clearInterval(countdownInterval);
            countdownInterval = null;
        }

        qrSection.classList.add('hidden');
        inputSection.classList.remove('hidden');
        timerProgress.style.width = '100%';
        timerProgress.classList.remove('warning', 'critical');
    }

    // CloudKit Integration (placeholder)
    // To implement:
    // 1. Include CloudKit JS: <script src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js"></script>
    // 2. Configure with your container ID
    // 3. Implement saveToCloudKit function

    /*
    async function initCloudKit() {
        CloudKit.configure({
            containers: [{
                containerIdentifier: 'iCloud.com.yourname.ennote',
                apiTokenAuth: {
                    apiToken: 'YOUR_API_TOKEN',
                    persist: false
                },
                environment: 'production'
            }]
        });
    }

    async function saveToCloudKit(stack) {
        const container = CloudKit.getDefaultContainer();
        const publicDB = container.publicCloudDatabase;

        const record = {
            recordType: 'Stack',
            recordName: stack.id,
            fields: {
                notes: { value: stack.notes },
                expiresAt: { value: stack.expiresAt },
                fetched: { value: 0 }
            }
        };

        await publicDB.saveRecords([record]);
    }
    */

    // Event Listeners
    notesInput.addEventListener('input', updateNoteCount);
    createStackBtn.addEventListener('click', createStack);
    newStackBtn.addEventListener('click', resetToInput);

    // Keyboard shortcut: Cmd/Ctrl + Enter to create stack
    notesInput.addEventListener('keydown', (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
            e.preventDefault();
            if (!createStackBtn.disabled) {
                createStack();
            }
        }
    });

    // Initialize
    updateNoteCount();

})();
