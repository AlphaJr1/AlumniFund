/**
 * Utility: Execute function with retry logic
 * Useful for critical operations that may fail due to transient errors
 */

/**
 * Execute a function with automatic retry on failure
 * @param {Function} fn - Async function to execute
 * @param {number} maxRetries - Maximum number of retry attempts (default: 3)
 * @param {number} baseDelay - Base delay in ms between retries (default: 1000)
 * @returns {Promise<any>} Result of the function execution
 */
async function executeWithRetry(fn, maxRetries = 3, baseDelay = 1000) {
    let lastError;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
        try {
            console.log(`Attempt ${attempt + 1}/${maxRetries}`);
            return await fn();
        } catch (error) {
            lastError = error;
            console.error(`Attempt ${attempt + 1} failed:`, error.message);

            // If this was the last attempt, throw the error
            if (attempt === maxRetries - 1) {
                console.error('All retry attempts exhausted');
                throw error;
            }

            // Calculate exponential backoff delay
            const delay = baseDelay * Math.pow(2, attempt);
            console.log(`Waiting ${delay}ms before retry...`);

            // Wait before retrying
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    throw lastError;
}

module.exports = {
    executeWithRetry,
};
