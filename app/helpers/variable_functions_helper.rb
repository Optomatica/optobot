module VariableFunctionsHelper

  def weather(city_name)
    p 'in weather given city_name = ', city_name[0]
    city = city_name.first
    acc_key = '8da14f08dc9fe885d86c975fa1620d15'
    url = "http://api.weatherstack.com/current?access_key=#{acc_key}&query=#{city}"

    uri = URI(url)
    request = Net::HTTP.get(uri)
    response = JSON.parse(request)

    (response.nil? || response['current'].nil?) ? 'error' : response['current']['temperature']
  end

  def first(*arr)
    arr.find(&:itself)
  end

  def sum(*num_arr)
    num_arr.inject(0.0) { |sum, i| sum + i.to_f }
  end

  def subtract(minuend, subtrahend)
    minuend.to_f - subtrahend.to_f
  end

  def multiply(*num_arr)
    num_arr.inject(1.0) { |product, i| product * i.to_f }
  end

  def division(dividend, divisor)
    dividend.to_f / divisor.to_f
  end

  def power(base, exponent)
    base.to_f**exponent.to_f
  end

  def int_division(dividend, divisor)
    dividend.to_i / divisor.to_i
  end

  def fv(rate, nper, pmt, pv, when_due=0)
    rate, nper, pmt, pv, when_due = rate.to_f, nper.to_f, pmt.to_f, pv.to_f, when_due.to_f
    if rate != 0
        tmp = (1 + rate)**nper
        -pv * tmp - pmt * (1 + rate * when_due) / rate * (tmp - 1)
    else
        -(pv + pmt * nper)
    end
  end

  def pmt(rate, nper, pv, fv, when_due=0)
    rate, nper, pv, fv, when_due = rate.to_f, nper.to_f, pv.to_f, fv.to_f, when_due.to_f
    tmp = (1 + rate)**nper
    fact = rate != 0 ? ((1 + rate * when_due) * (tmp - 1) / rate) : nper
    -(fv + pv * tmp) / fact
  end

  def pv(rate, nper, pmt, fv, when_due=0)
    rate, nper, pmt, fv, when_due = rate.to_f, nper.to_f, pmt.to_f, fv.to_f, when_due.to_f
    tmp = (1 + rate)**nper
    fact = rate != 0 ? ((1 + rate * when_due) * (tmp - 1) / rate) : nper
    -(fv + pmt * fact) / tmp
  end
  
  def ceil_nearest(number, precision)
    number, precision = number.to_f, precision.to_i
    Integer((Float(number) / precision).ceil * precision)
  end

  def format_int(number)
    whole, decimal = number.to_s.split('.')
    if whole.to_i < -999 || whole.to_i > 999
      whole.reverse!.gsub!(/(\d{3})(?=\d)/, '\\1,').reverse!
    end
    whole
  end

  def bool(truth)
    truth ? "true" : "false"
  end

  def between(number, low, high)
    number, low, high = [number, low, high].map(&:to_f)
    bool(low <= number && number <= high)
  end

  def greater_than(lhs, rhs)
    lhs, rhs = [lhs, rhs].map(&:to_f)
    bool(lhs > rhs)
  end

  def is_int(number)
    bool(number.to_f == number.to_i)
  end

  # The following functions are used for test purposes by Optobot's development team and will be removed later.
  def test_goal_house_recommended_init_invest(rate, nper, pmt, house_price, inflation_rate)
    rate, nper, pmt, house_price, inflation_rate = rate.to_f, nper.to_f, pmt.to_f, house_price.to_f, inflation_rate.to_f
    house_price = fv(inflation_rate, nper, 0, -house_price)
    pv = pv(rate, nper, -pmt, house_price, 0)
    pv = pv > 0 ? 0 : pv.abs
    ceil_nearest(pv, 50000)
  end
  def test_goal_house_recommended_monthly_invest(rate, nper, pv, house_price, inflation_rate)
    rate, nper, pv, house_price, inflation_rate = rate.to_f, nper.to_f, pv.to_f, house_price.to_f, inflation_rate.to_f
    house_price = fv(inflation_rate, nper, 0, -house_price)
    pmt = pmt(rate, nper, -pv, house_price, 0).abs / 12.0
    ceil_nearest(pmt, 1000)
  end

  def test_goal_retire_fund_needed(age, annual_income, death_age, inflation_rate, risk_free_rate)
      age, annual_income, death_age, inflation_rate, risk_free_rate = [age, annual_income, death_age, inflation_rate, risk_free_rate].map(&:to_f)
      if (age < 60)
        nper = years_to_retirement = 60 - age
        pv = annual_income
        income_at_retirement = fv(inflation_rate, nper, 0, -pv)
        nper = death_age - 60
        pmt = income_at_retirement
        retirement_fund_needed = pv(risk_free_rate, nper, -pmt, 0)
        ceil_nearest(retirement_fund_needed, 50000)
      else
        years_to_retirement = age < 76 ? 5 : 80 - age
        nper = years_to_retirement
        pv = annual_income
        income_at_retirement = fv(inflation_rate, nper, 0, -pv)
        nper = 90 - (age + years_to_retirement)
        pmt = income_at_retirement
        retirement_fund_needed = pv(risk_free_rate, nper, -pmt, 0)
        ceil_nearest(retirement_fund_needed, 50000)
      end
  end

  def test_goal_retire_monthly_incremental_invest_1(retirement_fund)
    retirement_fund = retirement_fund.to_f
    ceil_nearest(retirement_fund / 3000, 1000)
  end

  def test_goal_retire_fund_required(annual_income, death_age, age, years_to_retirement, inflation_rate, risk_free_rate)
    annual_income, death_age, age, years_to_retirement, inflation_rate, risk_free_rate = [annual_income, death_age, age, years_to_retirement, inflation_rate, risk_free_rate].map(&:to_f)
    nper = death_age - age - years_to_retirement
    pmt = fv(inflation_rate, years_to_retirement, 0, -annual_income)
    retirement_fund_needed = pv(risk_free_rate, nper, -pmt, 0)
  end

  def test_goal_retire_recommended_init_invest(retirement_fund, annual_income, death_age, age, years_to_retirement, monthly_incremental_invest, rate_of_return)
    retirement_fund, annual_income, death_age, age, years_to_retirement, monthly_incremental_invest, rate_of_return = [retirement_fund, annual_income, death_age, age, years_to_retirement, monthly_incremental_invest, rate_of_return].map(&:to_f)
    incremental_invest = monthly_incremental_invest * 12
    fv = retirement_fund
    nper = years_to_retirement
    init_investment = pv(rate_of_return, nper, -incremental_invest, fv)
    init_investment = init_investment > 0 ? 0 : init_investment.abs
    ceil_nearest(init_investment, 50000)
  end

  def test_goal_retire_monthly_invest(retirement_fund, init_invest, years_to_retirement, rate_of_return)
      retirement_fund, init_invest, years_to_retirement, rate_of_return = [retirement_fund, init_invest, years_to_retirement, rate_of_return].map(&:to_f)
      fv = retirement_fund
      nper = years_to_retirement
      pv = init_invest
      annual_invest_needed = pmt(rate_of_return, nper, -pv, fv)
      monthly_invest_needed = annual_invest_needed / 12
      ceil_nearest(monthly_invest_needed.abs, 1000)
  end

end
