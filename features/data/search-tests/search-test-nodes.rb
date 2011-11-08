example_nodes = {
  'a' => Proc.new do
    n = Chef::Node.new
    n.name 'a'
    n.run_list << "alpha"
    n.tag "apples"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-a"},
                 :b2 => {:a3 => "A1_B2_A3-a"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-a"},
                 :b2 => {:a3 => "B1_B2_A3-a"}
               }
             })
    n.value 1
    n.multi_word "foo bar baz"
    n
  end,

  'b' => Proc.new do
    n = Chef::Node.new
    n.name 'b'
    n.run_list << "bravo"
    n.tag "apes"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-b"},
                 :b2 => {:a3 => "A1_B2_A3-b"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-b"},
                 :b2 => {:a3 => "B1_B2_A3-b"}
               }
             })
    n.value 2
    n.multi_word "bar"
    n
  end,

  'ab' => Proc.new do
    n = Chef::Node.new
    n.name 'ab'
    n.run_list << "alpha"
    n.run_list << "bravo"
    n.tag "ack"
    n.multi_word "bar foo"
    n.quotes "\"one\" \"two\" \"three\""
    n
  end,

  'c' => Proc.new do
    n = Chef::Node.new
    n.name 'c'
    n.run_list << "charlie"
    n.tag "apes"
    n.nested({:a1 => {
                 :a2 => {:a3 => "A1_A2_A3-c"},
                 :b2 => {:a3 => "A1_B2_A3-c"}
               },
               :b1 => {
                 :a2 => {:a3 => "B1_A2_A3-c"},
                 :b2 => {:a3 => "B1_B2_A3-c"}
               }
             })
    n.value 3
    n.multi_word "foo"
    n
  end
}

example_data_bags = {
  'toys' => Proc.new do
    items = []
    bag = Chef::DataBag.new
    bag.name "toys"
    bag.save rescue nil
    item = Chef::DataBagItem.new
    item_data = {
      "id" => "marbles",
      "colors" => ["black", "white", "green", "red", "blue"]
    }
    item.data_bag "toys"
    item.raw_data = item_data
    item.save
    items << item

    item = Chef::DataBagItem.new
    item_data = {
      "id" => "balls",
      "baseballs" => 4,
      "soccerballs" => 2,
      "footballs" => 1
    }
    item.data_bag "toys"
    item.raw_data = item_data
    item.save
    items << item
    items
  end,

  'fruit' => Proc.new do
    items = []
    bag = Chef::DataBag.new
    bag.name "fruit"
    bag.save rescue nil
    item = Chef::DataBagItem.new
    item_data = {
      "id" => "citrus",
      "names" => ["orange", "lemon", "lime"]
    }
    item.data_bag "fruit"
    item.raw_data = item_data
    item.save
    items << item

    item = Chef::DataBagItem.new
    item_data = {
      "id" => "tropical",
      "names" => ["banana", "papaya", "mango"]
    }
    item.data_bag "fruit"
    item.raw_data = item_data
    item.save
    items << item
    items
  end
}

example_roles = {
  'prod' =>
  Proc.new do
    r = Chef::Role.new
    r.name "prod"
    r.run_list << "base"
    r.run_list << "role[monitoring]"
    r.default_attributes["key"] = 123
    r.save
    r
  end,
  'web' =>
  Proc.new do
    r = Chef::Role.new
    r.name "web"
    r.run_list << "base"
    r.run_list << "nginx"
    r.default_attributes["key"] = 456
    r.save
    r
  end

}

example_nodes.each do |name, nproc|
  n = nproc.call
  n.save
  puts "saved node: #{name}"
end

example_data_bags.each do |name, nproc|
  items = nproc.call
  puts "saved #{items.size} data bag items"
end

%w(ac ab cc).each do |client_name|
  client = Chef::ApiClient.new
  client.name client_name
  client.save
  puts "saved client: #{client.name}"
end

example_roles.each do |name, r|
  a_role = r.call
  puts "saved role: #{a_role.name}"
end
