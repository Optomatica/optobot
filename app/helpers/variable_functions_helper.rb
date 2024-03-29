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
  $inflation_rate = 0.09
  $annual_pmt_increase = 0.1
  $invest_return = 0.13

  def test_goal_recommended_init_invest(pv, percentage)
    pv, percentage = [pv, percentage].map(&:to_f)
    ceil_nearest(pv * percentage, 50000)
  end

  def test_goal_recommended_pmt(goal_price, nper, init_invest)
    goal_price, init_invest, nper = [goal_price, init_invest, nper].map(&:to_f)
    goal_fv = fv($inflation_rate, nper, 0, -goal_price)
    init_invest_fv = fv($invest_return, nper, 0, -init_invest)
    goal_invest_diff = goal_fv - init_invest_fv
    if (goal_invest_diff <= 0)
      return 0
    end
    goal_invest_diff_pv = -pv($invest_return, nper, 0, goal_invest_diff)
    yearly_amount = goal_invest_diff_pv / nper
    pmt = yearly_amount * (1 + $annual_pmt_increase)
    ceil_nearest(pmt / 12, 1000)
  end
  
  def test_goal_retire_recommended_init_invest(retirement_fund, nper, percentage)
    retirement_fund, nper, percentage = [retirement_fund, nper, percentage].map(&:to_f)
    rt_pv = pv($inflation_rate, nper, 0, retirement_fund)
    init_invest = test_goal_recommended_init_invest(-rt_pv, percentage)
  end

  def test_goal_retire_recommended_pmt(retirement_fund, nper, init_invest)
    retirement_fund, nper, init_invest = [retirement_fund, nper, init_invest].map(&:to_f)
    rt_pv = pv($inflation_rate, nper, 0, retirement_fund)
    test_goal_recommended_pmt(-rt_pv, nper, init_invest)
  end

  def test_goal_retire_fund_needed(age, annual_income, death_age)
    age, annual_income, death_age = [age, annual_income, death_age].map(&:to_f)
    if (age < 60)
      years_to_retirement = 60 - age
    elsif (age < 76)
      years_to_retirement = 5
    else
      years_to_retirement = 80 - age
    end
    
    retirement_fund_needed = test_goal_retire_fund_required(annual_income, death_age, age, years_to_retirement)
    m_rt_pmt = test_goal_retire_recommended_pmt(retirement_fund_needed, years_to_retirement, 0)
  end

  def test_goal_retire_fund_required(annual_income, death_age, age, years_to_retirement)
    annual_income, death_age, age, years_to_retirement = [annual_income, death_age, age, years_to_retirement].map(&:to_f)
    pmt = fv($inflation_rate, years_to_retirement, 0, -annual_income)
    retirement_fund_need = pmt * (death_age - (age + years_to_retirement))
  end
end
