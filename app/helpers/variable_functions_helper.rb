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

  def subtract(*num_arr)
    num_arr.first.to_f - num_arr.last.to_f
  end

  def multiply(*num_arr)
    num_arr.inject(1.0) { |product, i| product * i.to_f }
  end

  def division(*num_arr)
    num_arr.first.to_f / num_arr.last.to_f
  end

  def power(*num_arr)
    num_arr.first.to_f**num_arr.last.to_f
  end

  def int_division(*num_arr)
    num_arr.first.to_i / num_arr.last.to_i
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

  def round_nearest(x, num)
      x, num = x.to_f, num.to_f
      Integer((Float(x) / num).round * num)
  end

  def pmt(rate, nper, pv, fv, when_due=0)
      rate, nper, pv, fv, when_due = rate.to_f, nper.to_f, pv.to_f, fv.to_f, when_due.to_f
      tmp = (1 + rate)**nper
      fact = rate != 0 ? ((1 + rate * when_due) * (tmp - 1) / rate) : nper
      -(fv + pv * tmp) / fact
  end
end
