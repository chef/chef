require 'forwardable'
module MetricFu
  class Ranking
    extend Forwardable

    def initialize
      @items_to_score = {}
    end

    def top(num=nil)
      if(num.is_a?(Numeric))
        sorted_items[0,num]
      else
        sorted_items
      end
    end

    def percentile(item)
      index = sorted_items.index(item)
      worse_item_count = (length - (index+1))
      worse_item_count.to_f/length
    end

    def_delegator :@items_to_score, :has_key?, :scored?
    def_delegators :@items_to_score, :[], :[]=, :length, :each, :delete

    private

    def sorted_items
      @sorted_items ||= @items_to_score.sort_by {|item, score| -score}.map {|item, score| item}
    end

  end
end
