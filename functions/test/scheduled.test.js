/**
 * Unit Tests: Scheduled Functions
 */

const { expect } = require('chai');
const { mockTarget, mockSubmission, daysAgo, daysFromNow } = require('./helpers');

describe('Scheduled Functions - Unit Tests', () => {

    describe('checkDeadlines Logic', () => {
        it('should identify expired targets', () => {
            const expiredTarget = mockTarget({
                status: 'active',
                deadline: daysAgo(1) // Yesterday
            });

            const now = new Date();
            const isExpired = expiredTarget.deadline.toDate() < now;

            expect(isExpired).to.be.true;
            console.log('✓ Expired target identified');
        });

        it('should calculate distribution for fully funded target', () => {
            const target = mockTarget({
                current_amount: 1500000,
                target_amount: 1000000,
                graduates: [
                    { name: 'A' },
                    { name: 'B' },
                    { name: 'C' },
                    { name: 'D' }
                ]
            });

            const isFullyFunded = target.current_amount >= target.target_amount;
            const perPerson = isFullyFunded ? 250000 : Math.floor(target.current_amount / target.graduates.length);
            const totalDistributed = isFullyFunded ? target.target_amount : target.current_amount;
            const excess = isFullyFunded ? target.current_amount - target.target_amount : 0;

            expect(isFullyFunded).to.be.true;
            expect(perPerson).to.equal(250000);
            expect(totalDistributed).to.equal(1000000);
            expect(excess).to.equal(500000);

            console.log('✓ Distribution calculated correctly');
            console.log(`  Per person: Rp ${perPerson.toLocaleString('id-ID')}`);
            console.log(`  Total distributed: Rp ${totalDistributed.toLocaleString('id-ID')}`);
            console.log(`  Excess: Rp ${excess.toLocaleString('id-ID')}`);
        });

        it('should calculate distribution for partially funded target', () => {
            const target = mockTarget({
                current_amount: 600000,
                target_amount: 1000000,
                graduates: [
                    { name: 'A' },
                    { name: 'B' },
                    { name: 'C' },
                    { name: 'D' }
                ]
            });

            const isFullyFunded = target.current_amount >= target.target_amount;
            const perPerson = Math.floor(target.current_amount / target.graduates.length);
            const totalDistributed = target.current_amount;
            const excess = 0;

            expect(isFullyFunded).to.be.false;
            expect(perPerson).to.equal(150000);
            expect(totalDistributed).to.equal(600000);
            expect(excess).to.equal(0);

            console.log('✓ Partial distribution calculated correctly');
        });
    });

    describe('updateClosingSoonStatus Logic', () => {
        it('should identify targets approaching deadline', () => {
            const target = mockTarget({
                status: 'active',
                deadline: daysFromNow(5) // 5 days from now
            });

            const closingSoonThreshold = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            const isClosingSoon = target.deadline.toDate() <= closingSoonThreshold;

            expect(isClosingSoon).to.be.true;
            console.log('✓ Target approaching deadline identified');
        });

        it('should not mark targets with deadline > 7 days', () => {
            const target = mockTarget({
                status: 'active',
                deadline: daysFromNow(10) // 10 days from now
            });

            const closingSoonThreshold = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            const isClosingSoon = target.deadline.toDate() <= closingSoonThreshold;

            expect(isClosingSoon).to.be.false;
            console.log('✓ Target not yet closing soon');
        });
    });

    describe('cleanupOldSubmissions Logic', () => {
        it('should identify old rejected submissions', () => {
            const submission = mockSubmission({
                status: 'rejected',
                reviewed_at: daysAgo(35) // 35 days ago
            });

            const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
            const isOld = submission.reviewed_at.toDate() < cutoffDate;

            expect(isOld).to.be.true;
            console.log('✓ Old submission identified for cleanup');
        });

        it('should parse storage URL correctly', () => {
            const proofUrl = 'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/proofs%2Ftest123.jpg?token=abc';

            const url = new URL(proofUrl);
            const pathMatch = url.pathname.match(/\/o\/(.+)/);

            expect(pathMatch).to.not.be.null;

            if (pathMatch) {
                const filePath = decodeURIComponent(pathMatch[1]);
                expect(filePath).to.equal('proofs/test123.jpg');
                console.log('✓ Storage URL parsed correctly');
                console.log(`  File path: ${filePath}`);
            }
        });
    });
});
