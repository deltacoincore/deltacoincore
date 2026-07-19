#include <boost/test/unit_test.hpp>

#include <limits>
#include <stdlib.h>

#include <rpc/blockchain.h>
#include <test/test_bitcoin.h>

/* Equality between doubles is imprecise. Comparison should be done
 * with a small threshold of tolerance, rather than exact equality.
 */
static bool DoubleEquals(double a, double b, double epsilon)
{
    return std::abs(a - b) < epsilon;
}

static CBlockIndex* CreateBlockIndexWithNbits(uint32_t nbits)
{
    CBlockIndex* block_index = new CBlockIndex();
    block_index->nHeight = 46367;
    block_index->nTime = 1269211443;
    block_index->nBits = nbits;
    return block_index;
}

static void RejectDifficultyMismatch(double difficulty, double expected_difficulty) {
     BOOST_CHECK_MESSAGE(
        DoubleEquals(difficulty, expected_difficulty, 0.00001),
        "Difficulty was " + std::to_string(difficulty)
            + " but was expected to be " + std::to_string(expected_difficulty));
}

/* Given a BlockIndex with the provided nbits,
 * verify that the expected difficulty results.
 */
static void TestDifficulty(uint32_t nbits, double expected_difficulty)
{
    CBlockIndex* block_index = CreateBlockIndexWithNbits(nbits);
    double difficulty = GetDifficulty(block_index);
    delete block_index;

    RejectDifficultyMismatch(difficulty, expected_difficulty);
}

BOOST_FIXTURE_TEST_SUITE(blockchain_tests, BasicTestingSetup)

BOOST_AUTO_TEST_CASE(get_difficulty_for_very_low_target)
{
    TestDifficulty(0x1f111111, 0.000001);
}

BOOST_AUTO_TEST_CASE(get_difficulty_for_low_target)
{
    TestDifficulty(0x1ef88f6f, 0.000016);
}

BOOST_AUTO_TEST_CASE(get_difficulty_for_mid_target)
{
    TestDifficulty(0x1df88f6f, 0.004023);
}

BOOST_AUTO_TEST_CASE(get_difficulty_for_high_target)
{
    TestDifficulty(0x1cf88f6f, 1.029916);
}

BOOST_AUTO_TEST_CASE(get_difficulty_for_very_high_target)
{
    TestDifficulty(0x12345678, 5913134931067755359633408.0);
}

BOOST_AUTO_TEST_CASE(header_only_block_index_preserves_proof_type)
{
    CBlockHeader proof_of_stake_header;
    proof_of_stake_header.nVersion = BLOCK_VERSION_PROOF_OF_STAKE;
    CBlockIndex proof_of_stake_index(proof_of_stake_header);
    BOOST_CHECK(proof_of_stake_index.IsProofOfStake());
    BOOST_CHECK(!proof_of_stake_index.IsProofOfWork());

    CBlockHeader proof_of_work_header;
    CBlockIndex proof_of_work_index(proof_of_work_header);
    BOOST_CHECK(!proof_of_work_index.IsProofOfStake());
    BOOST_CHECK(proof_of_work_index.IsProofOfWork());
}

BOOST_AUTO_TEST_CASE(pos_network_weight_is_bounded_without_coin_rescaling)
{
    const double live_regression_estimate = 698531075432.8326;
    BOOST_CHECK_EQUAL(NormalizePoSNetworkWeight(live_regression_estimate), 698531075432ULL);
    BOOST_CHECK_EQUAL(NormalizePoSNetworkWeight(0), 0U);
    BOOST_CHECK_EQUAL(
        NormalizePoSNetworkWeight(std::numeric_limits<double>::infinity()),
        0U);
    BOOST_CHECK_EQUAL(
        NormalizePoSNetworkWeight(static_cast<double>(std::numeric_limits<uint64_t>::max()) * 4),
        std::numeric_limits<uint64_t>::max());
}

BOOST_AUTO_TEST_SUITE_END()
