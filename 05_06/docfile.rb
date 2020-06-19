require "pry" # khai báo thư viện debug
require "objspace" # khai báo thư viện tính ram sử dụng
require "benchmark" # khai báo thư viện tính thời gian thực thi

class FHM
  def initialize
    @items = [] # khai báo mảng chứa các item trong csdl giao dịch
    @arr_twu = {} # khai báo hash chứa lần lượt các item vs twu của nó có dạng, {item => twu(item)}
    @arr_items = [] # khai báo mảng chứa các item trong từng giao dịch
    @arr_ux = [] # khai báo mảng  chứa các giá trị hữu ích của từng item trong từng giao dịch
    @arr_tu = [] # khai báo mảng chứa các giá trị hữu ích của từng giao dịch
    # @min_utility = 30 # khai báo ngưỡng hữu ích tối thiếu
    # @min_utility = 4000 # khai báo ngưỡng hữu ích tối thiếu
    # @min_utility = 7400 # khai báo ngưỡng hữu ích tối thiếu
    @min_utility = 2268000 # khai báo ngưỡng hữu ích tối thiếu
    # @min_utility = 45000 # khai báo ngưỡng hữu ích tối thiếu
    # @min_utility = 45000 # khai báo ngưỡng hữu ích tối thiếu
    @I = {} # khai báo tập I chứa các item có twu cao hơn min_utility, có dạng {item=>twu,...}
    @arr_utility_list = {} # khai báo hash chứa các danh sách hữu ích của từng item, có dạng {{item=>giao dịch}=>{util=>rutil},...}
    @arr_HUI = {} # mảng chứa itemset HUI, có dạng {itemset=>util}
    # @hash_itemset_ULs = {}
    # @count_test = 0
    @dem = 0
    @arr_itemset = []
    @arr_extensions_search = []
  end

  def read_file_db # đọc files txt
    arr_line = []
    # f = File.open("./DB_Utility.txt", "r")
    # f = File.open("./BMS_utility_spmf.txt", "r")
    # f = File.open("./chainstore.txt", "r")
    # f = File.open("./foodmart.txt", "r")
    # f = File.open("./foodmart_test.txt", "r")
    f = File.open("./BMS_utility_spmf1.txt", "r")
    f.each_line.with_index do |line, index|
      arr_line << line.split(/:/)
      @arr_items << arr_line[index][0].gsub(/\s+/, ":").split(/:/).map { |x| x.to_i } # danh sách items trong từng giao dịch ### update
      @arr_tu << arr_line[index][1] # danh sách tổng lợi nhuận của từng giao dịch (tu(x))
      @arr_ux << arr_line[index][2].gsub(/\s+/, ":").split(/:/) # danh sách lợi nhuận của từng item trong từng giao dịch
    end
    @items = @arr_items.join(",").split(",").uniq.map { |x| x.to_i }.sort # danh sách các item trong csdl ### update
  end

  def calculate_TWU # tính twu của từng item trong csdl
    @items.each do |item|
      tu = 0
      @arr_items.each_with_index do |arr_items, index|
        if arr_items.include?(item)
          tu += @arr_tu[index].to_i
        end
      end
      # mảng chứa các TWU của từng items
      @arr_twu[item] = tu ### update
    end
  end

  def calculate_I
    i = {}
    @items_I = [] # mảng chứa các item có TWU lớn hơn min_untility
    @arr_twu.each do |k, v|
      if v >= @min_utility
        i[k] = v
        @items_I << k
      end
    end
    # Mảng chứa các item > min_utility và được sắp xếp tăng dần theo TWU
    @I = i.sort_by { |k, v| v }.to_h
  end

  def utility_list_items
    @arr_utility_list = {} # danh sach huu ich co dang: {{item=>td}=>{iutil=>rutil}}
    @arr_sum_utility_list = {} # mảng chứa các item với tổng util, rituil của nó có dạng: {"items"=>{util=>rutil}}
    @I.each_key do |items|
      @arr_items.each_with_index do |arr, index|
        if arr.include?(items)
          @arr_items[index].each_with_index do |item_in_td, index_item|
            if items == item_in_td
              arr_items_td = {}
              arr_iutil_rutil = {}
              arr_iutil = @arr_ux[index][index_item].to_i
              arr_rutil = (@arr_tu[index].to_i - arr_iutil)
              arr_iutil_rutil[arr_iutil] = arr_rutil
              arr_items_td[items] = index + 1
              @arr_utility_list[arr_items_td] = arr_iutil_rutil
            end
          end
        end
      end
      util = 0
      rutil = 0
      sum_util_rutil = {}
      @arr_utility_list.each do |key, value|
        if key.has_key?(items)
          util += value.keys.inject(:+)
          rutil += value.values.inject(:+)
        end
      end
      sum_util_rutil[util] = rutil
      @arr_sum_utility_list[items] = sum_util_rutil  # utility list cua item co dang: {item => {util=>rutil}}
    end
  end

  def twu_itemset(a, b) # tính twu của 2 items
    sum_twu_itemset = 0
    @arr_items.each_with_index do |item, index|
      if item.include?(a) && item.include?(b) ### update
        sum_twu_itemset += @arr_tu[index].to_i
      end
    end
    sum_twu_itemset
  end

  def eucs # Xây dựng cấu trúc EUCS (trường hợp 2-7, 3-5 bị sai trong tài liệu)
    @arr_eucs = {}
    a = 2
    for i in 1...(@items_I.length)
      for j in a..(@items_I.length)
        hash_a_b = {}
        hash_a_b[@items_I[i - 1]] = @items_I[j - 1]
        @arr_eucs[hash_a_b] = twu_itemset(i, j)
      end
      a += 1
    end
    @arr_eucs # mảng chứa có cặp items vs TWU của nó có dạng {"items1"=>"items2"}=> TWU of 2 items
  end

  def algorithm_1_FHM
    Benchmark.bm(5) do |x|
      x.report("======= Thuat toan 1: =======  ") {
        # Benchmark.bm(5) do |x|
        # x.report("Times khoi tao thuat toan 1: ") {
        read_file_db
        calculate_TWU
        calculate_I
        utility_list_items # 15.786110
        # eucs # 854.717365
        # }
        # end
        # binding.pry
        arr_extensions_p = []
        @I.keys.each_with_index do |item, index|
          dem = 0
          arr_ULs = []
          # arr_extensions_pp = []
          # item = 1
          # calculate_utility_list_itemset(["3", "5"])
          # hash_itemset_ULs = {}
          # hash_itemset_ULs[calculate_arr_extensions_p(item)[index]] = calculate_utility_list_itemset(calculate_arr_extensions_p(item)[index])
          # arr_ULs << hash_itemset_ULs # [{["3", "6"]=>[{{"3"=>1}=>{1=>29}, {"6"=>1}=>{5=>25}}]}]
          # binding.pry
          # Benchmark.bm(5) do |x|
          # x.report("Times dau vao cua thuat toan 2: ") {
          calculate_arr_extensions_p(item).each_with_index do |itemset_ULs, index_ULs| # tinh ULs cho danh sach phan mo rong
            # if !arr_extensions_p.include?(itemset_ULs)
            hash_itemset_ULs = {}
            # hash_itemset_ULs[itemset_ULs] = calculate_utility_list_itemset(itemset_ULs) # xem lại đoạn này vs thuật toán 3
            hash_itemset_ULs[itemset_ULs] = calculate_utility_list_itemset_stand(calculate_utility_list_itemset(itemset_ULs)) # xem lại đoạn này vs thuật toán 3
            arr_ULs << hash_itemset_ULs # Time: 9.140905
            # arr_extensions_pp << itemset_ULs
            # arr_extensions_p << itemset_ULs
            # end
          end
          # }
          # end
          # calculate_utility_list_itemset(["3", "5"])
          # binding.pry
          puts "-----------------------"
          puts "**** Itemset: #{[item]}"
          puts "-----------------------"
          Benchmark.bm(5) do |x|
            x.report("-----> #{dem}. Times hoan tat 1 itemset: ") {

              # algorithm_2([1, 7], [[1, 2, 3]], [{[1, 2, 3]=>[{1=>{16=>20}}]}])
              if !calculate_arr_extensions_p(item).empty?
                algorithm_2([item], calculate_arr_extensions_p(item), arr_ULs)
              end
              # algorithm_2([item], arr_extensions_pp, arr_ULs)
            }
          end
          dem += 1
          # p @arr_HUI
          # binding.pry
        end
        # binding.pry
        # end
        puts "Result ==>> #{@arr_HUI} : #{@arr_HUI.length}"
        # p @arr_HUI
        # binding.pry
      }
    end
    binding.pry
  end

  def algorithm_2(p, arr_extensions_p, arr_ULs_X)
    puts "-------------------------"
    puts "*** ALGORITHM_2 => itemset_p: #{p}, arr_extensions_p: #{arr_extensions_p}, arr_ULs_X: #{arr_ULs_X}"
    puts "-------------------------"
    test = {}
    dem = 0
    # binding.pry
    arr_extensions_p.each_with_index do |itemset_px, index| # duyêt các itemset px thuộc phần mở rộng của itemset p
      if !@arr_HUI.has_key?(itemset_px) && !@arr_itemset.include?(itemset_px) && !@arr_extensions_search.include?(itemset_px) && !arr_ULs_X[index][itemset_px].empty?
        if sum_util(arr_ULs_X[index][itemset_px]) >= @min_utility # điều kiên sum util trong danh sách hữu ích của px
          @arr_HUI[itemset_px] = sum_util(arr_ULs_X[index][itemset_px]) # xuất ra itemset là HUI
          dem += 1
          test[itemset_px] = sum_util(arr_ULs_X[index][itemset_px])
          # puts "Test: #{test}"
          puts "-------------------------"
          puts "#{dem}. Ket qua Loop_arr_HUI: #{test}"
          puts "-------------------------"
          # return @arr_HUI
        end
        # binding.pry
        # sum_util_rutil([{1=>{4030=>7159}}])
        if sum_util_rutil(arr_ULs_X[index][itemset_px]) >= @min_utility
          arr_extensions_px = [] # mảng chứa các itemset thuộc phần mở rộng của itemset px
          arr_ULs_PX = []
          arr_extensions_p.each do |itemset_py|
            if itemset_py != itemset_px && twu([itemset_px, itemset_py]) >= @min_utility # twu có vẫn đề - đã tối ưu
              itemset_px_py = []
              itemset_px_py << itemset_px
              itemset_px_py << itemset_py
              # binding.pry
              if !@arr_itemset.include?(itemset_px_py.join(";").split(";").map { |x| x.to_i }.uniq.sort) &&
                 !@arr_extensions_search.include?(itemset_px_py.join(";").split(";").map { |x| x.to_i }.uniq.sort)
                #  (!@arr_extensions_search.include?(itemset_px) ||
                #   !@arr_extensions_search.first.include?(itemset_px))
                # @arr_itemset << itemset_px
                arr_extensions_px << itemset_px_py.join(";").split(";").map { |x| x.to_i }.uniq.sort
                # @arr_extensions_search << itemset_px_py.join(";").split(";").map { |x| x.to_i }.uniq.sort
                hash_itemset_ULs = {}
                hash_itemset_ULs[itemset_px_py.join(";").split(";").map { |x| x.to_i }.uniq.sort] = algorithm_3(p, itemset_px, itemset_py)
                arr_ULs_PX << hash_itemset_ULs
              end
            end
          end
          if !arr_extensions_px.empty?
            # puts "*** ALGORITHM_2 => itemset_px: #{itemset_px}, arr_extensions_px: #{arr_extensions_px}, arr_ULs_PX: #{arr_ULs_PX}"
            @arr_itemset << itemset_px
            # binding.pry
            # @arr_extensions_search << arr_extensions_px
            # if !arr_extensions_px.length == 1
            #   # p "return OUT"
            #   break
            # else
            algorithm_2(itemset_px, arr_extensions_px, arr_ULs_PX)
            # end
            if arr_extensions_px.length == 1 && !@arr_itemset.include?(arr_extensions_px.first)
              @arr_extensions_search << arr_extensions_px.first
            end
          end
        end
      end
    end
    @dem += 1
    # puts @dem
    puts "#{@dem}. KET QUA cua 1 vong lap:  #{@arr_HUI}: #{@arr_HUI.length}"
    if @dem == 100
      binding.pry
    end
  end

  def algorithm_3(p, itemset_px, itemset_py)
    utility_list_itemset_p = calculate_utility_list_itemset(p)
    utility_list_itemset_py = calculate_utility_list_itemset(itemset_py)
    utility_list_of_pxy = [] # mảng chứa các tuple của danh sách hữu ích của pxy
    # utility_list_of_itemset("2").each do |ex| # duyệt các bộ ex thuộc danh sách hữu ích của itemset px
    calculate_utility_list_itemset(itemset_px).each do |ex|
      # exx.first
      # binding.pry
      # end
      # utility_list_of_itemset("4").each do |ey| # duyệt các bộ ey thuộc danh sách hữu ích của itemset py
      utility_list_itemset_py.each do |ey|

        # binding.pry
        if ex.first[0].values[0] == ey.first[0].values[0] # điều kiện ex.tid = ey.tid
          # binding.pry
          exy = {} # khai báo hash lưu giá trị có dạng {tid => {util=>rutil}}
          unless utility_list_itemset_p.empty? # điều kiên danh sách hữu ích của itemset p khác rỗng
            utility_list_itemset_p.each do |itemset_p|
              # binding.pry
              if itemset_p.first[0].values[0] == ex.first[0].values[0] # duyêt các bộ e trong danh sách hữu ích của itemset p và so sánh td của itemset p có cùng td vs itemset ex không.
                # binding.pry
                hash_util_ruil = {} # khai báo hash lưu giá trị có dạng {util=>rutil}
                hash_util_ruil[sum_util_itemset(ex) + sum_util_itemset(ey) - sum_util_itemset(itemset_p)] = ey.values[ey.length - 1].values[0]
                exy[ex.first[0].values[0]] = hash_util_ruil

                # ey.values[p.length-1].keys[0]
                # sum_util_itemset(p)
                # binding.pry
              end
            end
          else # điều kiên danh sách hữu ích của p là rỗng
            hash_util_ruil = {} # khai báo hash lưu giá trị có dạng {util=>rutil}
            hash_util_ruil[sum_util_itemset(ex) + sum_util_itemset(ey)] = ey.values[ey.length - 1].values[0]
            exy[ex.first[0].values[0]] = hash_util_ruil
            # exy[ex.first[0].values[0]] = hash_util_ruil
          end
          unless exy.empty? # loại bõ nhưng phần tử rỗng ra khỏi danh sách hữu ích
            utility_list_of_pxy << exy
          end
        end
      end
    end
    utility_list_of_pxy
    # binding.pry
  end

  def calculate_arr_extensions_p(p) # tạo mảng chứa các itemset px là phần mở rộng của itemset p
    arr_extensions_p = []
    @I.keys.each do |itemset_px|
      # arr_ext_px = []
      if itemset_px != p && !@arr_itemset.include?([p, itemset_px].sort!)
        # @arr_extensions_search << [p, itemset_px].sort!
        arr_extensions_p << [p, itemset_px].sort! # đóng ngoặc vuông lai :)) #### update
        # binding.pry
      end
    end
    arr_extensions_p
    # binding.pry
  end

  def calculate_utility_list_itemset_stand(p)
    # binding.pry
    arr_ULs = []
    p.each do |itemset|
      sum_util = 0
      sum_rutil = 0
      hash_util_rutil = {}
      hash_td_util_rutil = {}
      itemset.values.each do |uls|
        sum_util += uls.keys[0]
      end
      sum_rutil = itemset.values.last.values[0]
      hash_util_rutil[sum_util] = sum_rutil
      hash_td_util_rutil[itemset.keys[0].values[0]] = hash_util_rutil
      arr_ULs << hash_td_util_rutil
    end
    arr_ULs
    # binding.pry
  end

  def calculate_utility_list_itemset(p) # danh sách hữu ích của 1 itemset
    # binding.pry
    result = []
    if p.nil? || p.empty?
      return result
    else
      hash_result = []
      if p.length == 1 # nếu itemset chỉ có 1 item thì truy xuất trong mảng đã tính (chứa tất cả các item vs tổng util và rutil)
        # return @arr_sum_utility_list[p[0]].keys[0]
        # hash_result = []
        p.each do |item|
          @arr_utility_list.each do |key, value|
            hash_utility = {} # tạo hash chứa tẩt cả các tuple của từng item trong itemset
            if key.has_key?(item)
              hash_utility[key] = value
              hash_result << hash_utility
            end
          end
        end
        return hash_result
      else
        hash_utility = {} # tạo hash chứa tẩt cả các tuple của từng item trong itemset
        p.each do |item|
          @arr_utility_list.each do |key, value|
            if key.has_key?(item)
              hash_utility[key] = value
            end
          end
        end
        # binding.pry
        # hash_utility_simple = {}
        # hash_result = [] # tao mảng chứa các tuple trong dánh sách hữu ích itemset
        # twu = 0 # khai báo twu để lưu tổng tu của itemset trong csdl
        arr_td_itemset = []
        hash_utility.keys.each do |key|
          arr_td_itemset << key.values[0]
        end

        arr_td_itemset.uniq.each do |td|
          # td = key.values[0] # gán td = giao dịch đầu tiên của item tồn tại trong các tuple của từng item trong itemset
          hash_utility_simple = {}
          p.each do |item|
            if hash_utility[item => td] != nil # điều kiện item đó có tồn tại trong giao dich này không.
              hash_utility_simple[item => td] = hash_utility[item => td]
            end
            # binding.pry
          end
          if hash_utility_simple.length == p.length # nếu số item trong itemset bằng số item trong mảng p thì...
            hash_result << hash_utility_simple # mảng chứa các ULs của itemset trong 1 giao dịch
            # return hash_result
            # twu += @arr_tu[hash_result[0].first[0].values[0] - 1].to_i
            # binding.pry
          end
        end

        # binding.pry
      end
      # binding.pry
      hash_result
    end
  end

  def sum_util(hash) # bị lỗi sum_util (hash ko xác định là gì,,,,)
    # binding.pry
    sum_util = 0
    if !hash.nil?
      unless hash.empty?
        # binding.pry
        hash.each do |arr_hash|
          unless arr_hash.empty?
            arr_hash.each do |tuple|
              # binding.pry
              unless tuple.empty? && tuple[1].empty?
                # binding.pry
                sum_util += tuple[1].keys[0].to_i
              end
            end
          end
        end
      end
    end
    # binding.pry
    sum_util # loi hash xem lai 1 item vs itemset
  end

  def sum_util_rutil(hash)
    sum_util_rutil = 0
    if !hash.nil?
      hash.each do |arr_hash|
        arr_hash.each do |tuple|
          sum_util_rutil += tuple[1].keys[0] + tuple[1].values[0]
        end
      end
    end
    sum_util_rutil
  end

  def sum_util_itemset(arr_ULs_X)
    sum = 0
    arr_ULs_X.each do |itemset|
      sum += itemset[1].keys[0].to_i
    end
    sum
  end

  # xem lai toi uu chua
  def twu(itemset) # tính twu của 1 mảng items (itemset)
    itemset_format = itemset.join(",").split(",").map { |x| x.to_i }.uniq ### update
    c = 0
    if !itemset_format.empty?
      @arr_items.each_with_index do |arr_td_item, index|
        td = 0
        itemset_format.each do |item|
          if arr_td_item.include?(item)
            td += 1
          end
          # binding.pry
        end
        if td == itemset_format.length
          c += @arr_tu[index].to_i
        end
      end
    end
    c
    # binding.pry
  end
end

main = FHM.new
Benchmark.bm(5) do |x|
  x.report("Itemset HUI: ") { p "Memory: #{ObjectSpace.memsize_of(main.algorithm_1_FHM)}" }
end
# p ObjectSpace.memsize_of(main.algorithm_1_FHM)
# binding.pry
