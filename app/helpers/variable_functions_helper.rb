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

  # The following functions are for used test purposes by Optobot's development team and will be removed later.
  def test_fv(rate, nper, pmt, pv, when_due=0)
    rate, nper, pmt, pv, when_due = rate.to_f, nper.to_f, pmt.to_f, pv.to_f, when_due.to_f
    if rate != 0
        tmp = (1 + rate)**nper
        -pv * tmp - pmt * (1 + rate * when_due) / rate * (tmp - 1)
    else
        -(pv + pmt * nper)
    end
  end

  def test_pmt(rate, nper, pv, fv, when_due=0)
    rate, nper, pv, fv, when_due = rate.to_f, nper.to_f, pv.to_f, fv.to_f, when_due.to_f
    tmp = (1 + rate)**nper
    fact = rate != 0 ? ((1 + rate * when_due) * (tmp - 1) / rate) : nper
    -(fv + pv * tmp) / fact
  end

  def test_pv(rate, nper, pmt, fv, when_due=0)
    rate, nper, pmt, fv, when_due = rate.to_f, nper.to_f, pmt.to_f, fv.to_f, when_due.to_f
    tmp = (1 + rate)**nper
    fact = rate != 0 ? ((1 + rate * when_due) * (tmp - 1) / rate) : nper
    -(fv + pmt * fact) / tmp
  end

  def test_goal_house_recommended_init_invest(rate, nper, pmt, fv)
    rate, nper, pmt, fv = rate.to_f, nper.to_f, pmt.to_f, fv.to_f
    pmt *= -1
    pv = test_pv(rate, nper, pmt, fv, 0).abs
    Integer((Float(pv) / 50000).ceil * 50000)
  end

  def test_goal_house_recommended_monthly_invest(rate, nper, pv, fv)
    rate, nper, pv, fv = rate.to_f, nper.to_f, pv.to_f, fv.to_f
    pv *= -1
    pmt = test_pmt(rate, nper, pv, fv, 0).abs / 12.0
    Integer((Float(pmt) / 50000).ceil * 50000)
  end
end
