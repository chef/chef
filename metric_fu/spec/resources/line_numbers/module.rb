module KickAss

  def get_beat_up?
    [1,2,3].inject {|m,o| m = m + o}
    true
  end

  def fight
    "poorly"
  end
end