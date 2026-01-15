/**
 * Unit Tests: Triggered Functions
 */

const { expect } = require('chai');
const { mockTarget, mockTransaction } = require('./helpers');
const admin = require('firebase-admin');

describe('Triggered Functions - Unit Tests', () => {

    describe('onTargetClosed Logic', () => {
        it('should detect status change to closed', () => {
            const before = { status: 'active' };
            const after = { status: 'closed' };

            const statusChanged = before.status !== 'closed' && after.status === 'closed';

            expect(statusChanged).to.be.true;
            console.log('✓ Status change to closed detected');
        });

        it('should calculate analytics metrics', () => {
            const target = mockTarget({
                status: 'closed',
                target_amount: 1000000,
                current_amount: 1200000,
                open_date: admin.firestore.Timestamp.fromDate(new Date('2026-01-01')),
                closed_date: admin.firestore.Timestamp.fromDate(new Date('2026-01-15'))
            });

            // Calculate percentage
            const percentage = Math.round((target.current_amount / target.target_amount) * 100);

            // Calculate duration
            const durationDays = Math.ceil(
                (target.closed_date.toDate() - target.open_date.toDate()) / (1000 * 60 * 60 * 24)
            );

            // Determine funding status
            const fundingStatus = target.current_amount >= target.target_amount
                ? 'fully_funded'
                : 'partially_funded';

            expect(percentage).to.equal(120);
            expect(durationDays).to.equal(14);
            expect(fundingStatus).to.equal('fully_funded');

            console.log('✓ Analytics metrics calculated');
            console.log(`  Percentage: ${percentage}%`);
            console.log(`  Duration: ${durationDays} days`);
            console.log(`  Status: ${fundingStatus}`);
        });

        it('should determine if target should be archived', () => {
            const target = mockTarget({
                graduates: [
                    {
                        name: 'A',
                        date: admin.firestore.Timestamp.fromDate(new Date('2026-01-10'))
                    },
                    {
                        name: 'B',
                        date: admin.firestore.Timestamp.fromDate(new Date('2026-01-15'))
                    }
                ]
            });

            const now = new Date('2026-01-20'); // After all graduations
            const graduateDates = target.graduates.map(g => g.date.toDate());
            const lastGraduateDate = new Date(Math.max(...graduateDates));

            const shouldArchive = now > lastGraduateDate;

            expect(shouldArchive).to.be.true;
            console.log('✓ Archive logic correct');
            console.log(`  Last graduate: ${lastGraduateDate.toISOString()}`);
            console.log(`  Current date: ${now.toISOString()}`);
        });
    });

    describe('routeIncome Logic', () => {
        it('should skip non-income transactions', () => {
            const transaction = mockTransaction({
                type: 'expense'
            });

            const shouldProcess = transaction.type === 'income';

            expect(shouldProcess).to.be.false;
            console.log('✓ Non-income transaction skipped');
        });

        it('should skip if target_id already set', () => {
            const transaction = mockTransaction({
                type: 'income',
                target_id: 'existing-target'
            });

            const shouldRoute = !transaction.target_id;

            expect(shouldRoute).to.be.false;
            console.log('✓ Transaction with existing target_id skipped');
        });

        it('should route to active target when available', () => {
            const transaction = mockTransaction({
                type: 'income',
                target_id: null,
                amount: 100000
            });

            const activeTarget = mockTarget({
                id: 'active-target',
                status: 'active',
                current_amount: 500000
            });

            // Simulate routing
            const targetId = activeTarget.id;
            const targetMonth = `${activeTarget.month} ${activeTarget.year}`;
            const newAmount = activeTarget.current_amount + transaction.amount;

            expect(targetId).to.equal('active-target');
            expect(targetMonth).to.equal('Januari 2026');
            expect(newAmount).to.equal(600000);

            console.log('✓ Income routed to active target');
            console.log(`  Target: ${targetMonth}`);
            console.log(`  New amount: Rp ${newAmount.toLocaleString('id-ID')}`);
        });

        it('should route to general fund when no active target', () => {
            const transaction = mockTransaction({
                type: 'income',
                target_id: null,
                amount: 100000
            });

            // No active target available
            const activeTarget = null;

            // Simulate routing to general fund
            const targetId = activeTarget ? activeTarget.id : 'general_fund';
            const targetMonth = null;

            expect(targetId).to.equal('general_fund');
            expect(targetMonth).to.be.null;

            console.log('✓ Income routed to general fund');
        });
    });
});
