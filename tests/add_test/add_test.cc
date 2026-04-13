#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <string>

// ========== 1. gtest 测试 ==========
int add(int a, int b) { return a + b; }

TEST(AddTest, HandlesPositiveInput) { EXPECT_EQ(add(1, 2), 3); }
TEST(AddTest, HandlesMixedSigns) { EXPECT_EQ(add(-1, 1), 0); }
TEST(AddTest, HandlesZero) { EXPECT_EQ(add(0, 0), 0); }

// ========== 2. gmock 测试 ==========
class IAdder {
 public:
  virtual ~IAdder() = default;
  virtual int add(int a, int b) = 0;
  virtual void log(const std::string& msg) = 0;
};

class MockAdder : public IAdder {
 public:
  MOCK_METHOD(int, add, (int a, int b), (override));
  MOCK_METHOD(void, log, (const std::string& msg), (override));
};

class Calculator {
 public:
  explicit Calculator(IAdder& adder) : adder_(adder) {}
  int compute(int a, int b) {
    adder_.log("compute called");
    return adder_.add(a, b);
  }

 private:
  IAdder& adder_;
};

TEST(CalculatorTest, CallsAdderWithExpectedArgs) {
  MockAdder mock;

  EXPECT_CALL(mock, log("compute called")).Times(1);
  EXPECT_CALL(mock, add(3, 4)).WillOnce(testing::Return(7));

  Calculator calc(mock);
  EXPECT_EQ(calc.compute(3, 4), 7);
}

TEST(CalculatorTest, UsesMatchers) {
  MockAdder mock;

  EXPECT_CALL(mock, log(testing::_)).Times(1);
  EXPECT_CALL(mock, add(testing::Gt(0), testing::Gt(0)))
      .WillOnce(testing::Return(100));

  Calculator calc(mock);
  EXPECT_EQ(calc.compute(5, 10), 100);
}

TEST(CalculatorTest, DoesNotCallAddWhenNotUsed) {
  MockAdder mock;
  EXPECT_CALL(mock, add(testing::_, testing::_)).Times(0);
}