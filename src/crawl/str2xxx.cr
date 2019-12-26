module Crawl::Str2xxx
  ######################################################################
  ### int
  
  def str2int(s : String) : Int32
    case s
    when /^(\d+)m$/i
      $1.to_i * 1_000_000
    when /^(\d+)k$/i
      $1.to_i * 1_000
    when /^(\d+)$/i
      $1.to_i
    else
      raise ArgumentError.new("expects '\d+[mk]?', but got '#{s}'")
    end
  end

  def str2int?(s : String) : Int32?
    str2int(s)
  rescue ArgumentError
    nil
  end
  
  def str2range_int(range : String) : Range(Int32, Int32)
    case range
    when /\.\.|-/
      a, b = range.split(/\.\.|-/, 2)
      b ||= a
      str2int(a) .. str2int(b)
    else
      v = str2int(range)
      v .. v
    end
  end

  def str2range_int?(range : String) : Range(Int32, Int32)?
    str2range_int(range)
  rescue ArgumentError
    nil
  end

  ######################################################################
  ### float
  
  def str2float(s : String) : Float64
    case s
    when /^(\d+(.\d+)?)m$/i
      $1.to_f * 1_000_000
    when /^(\d+(.\d+)?)k$/i
      $1.to_f * 1_000
    when /^(\d+(.\d+)?)$/i
      $1.to_f
    else
      raise ArgumentError.new("expects '\d+(.\d+)?[mk]?', but got '#{s}'")
    end
  end

  def str2float?(s : String) : Float64?
    str2float(s)
  rescue ArgumentError
    nil
  end
  
  def str2range_float(range : String) : Range(Float64, Float64)
    case range
    when /\.\.|-/
      a, b = range.split(/\.\.|-/, 2)
      b ||= a
      str2float(a) .. str2float(b)
    else
      v = str2float(range)
      v .. v
    end
  end

  def str2range_float?(range : String) : Range(Float64, Float64)?
    str2range_float(range)
  rescue ArgumentError
    nil
  end

  extend self
end
