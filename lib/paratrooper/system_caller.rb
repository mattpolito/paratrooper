SystemCaller = Struct.new(:call) do
  def execute
    system(call)
  end
end
