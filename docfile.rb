require "pry"

class FHM
  def initialize
    @items = []
    @arr_twu = {}
    @arr_items = []
    @arr_ux = []
    @arr_tu = []
    @min_utility = 30
    @I = {}
    @arr_utility_list = {}
    @arr_HUI = {} # mảng chứa itemset HUI
  end

  def read_file_db
    arr_line = []
    f = File.open("./DB_Utility.txt", "r")
    f.each_line.with_index do |line, index|
      arr_line << line.split(/:/)

      # danh sách sản phẩm trong từng giao dịch
      @arr_items << arr_line[index][0].gsub(/\s+/, ":").split(/:/)

      # danh sách tổng lợi nhuận của từng giao dịch (tu(x))
      @arr_tu << arr_line[index][1]

      # danh sách lợi nhuận của từng sản phẩm trong từng giao dịch
      @arr_ux << arr_line[index][2].gsub(/\s+/, ":").split(/:/)
    end
    # danh sách các sản phẩm trong csdl
    @items = @arr_items.join(",").split(",").uniq.sort
  end

  def calculate_TWU
    @items.each do |item|
      tu = 0
      @arr_items.each_with_index do |arr_items, index|
        if arr_items.include?(item)
          tu += @arr_tu[index].to_i
        end
      end
      # mảng chứa các TWU của từng items
      @arr_twu[item] = tu
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
      if item.include?("#{a}") && item.include?("#{b}")
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
    read_file_db
    calculate_TWU
    calculate_I
    utility_list_items
    eucs
    @I.keys.each do |item|
      # if @arr_sum_utility_list[item].keys[0] > @min_utility
      #   @arr_HUI[item] = @arr_sum_utility_list[item].keys[0]
      # end
      # algorithm_2_search("7")
      algorithm_2(item, calculate_arr_extensions_p(item))

      # calculate_sum_utility_hui(["7"])
      # calculate_sum_utility_hui(["1","2","3","4","5","6"])
      # binding.pry
    end
  end

  def calculate_arr_extensions_p(p) # tạo mảng chứa các itemset px là phần mở rộng của itemset p
    arr_extensions_p = []
    @I.keys.each do |itemset_px|
      if itemset_px != p
        arr_extensions_p << itemset_px
      end
    end
    # binding.pry
    arr_extensions_p
  end

  def calculate_sum_utility_hui(p)
    # binding.pry
    if p.length == 1
      return @arr_sum_utility_list[p[0]].keys[0]
    else
      hash_utility = {}
      p.each do |item|
        @arr_utility_list.each do |key, value| # value == @arr_utility_list[item => key.values[0]]
          if key.has_key?(item)
            hash_utility[key] = value
          end
        end
      end
      # hash_utility_simple = {}
      hash_result = []
      hash_utility.each do |key, value|
        td = key.values[0]
        hash_utility_simple = {}
        p.each do |item|
          if hash_utility[item => td] != nil
            hash_utility_simple[item => td] = hash_utility[item => td]
          end
        end
        if hash_utility_simple.length == p.length
          hash_result << hash_utility_simple
          # return hash_result
          # binding.pry
        end
      end
      # hash
      # binding.pry
      sum_util = 0
      hash_result.uniq.each do |arr_hash|
        arr_hash.each do |tuple|
          sum_util += tuple[1].keys[0]
        end
      end
      # binding.pry
    end
  end

  def algorithm_2(p, arr_extensions_p)
    
    arr_extensions_p.each do |itemset_px| # duyêt các itemset px thuộc phần mở rộng của itemset p
      # binding.pry
      if @arr_sum_utility_list[itemset_px].keys[0] >= @min_utility # điều kiên sum util trong danh sách hữu ích của px
        @arr_HUI[itemset_px] = @arr_sum_utility_list[itemset_px].keys[0] # xuất ra itemset là HUI
      end
      if @arr_sum_utility_list[itemset_px].keys[0] + @arr_sum_utility_list[itemset_px].values[0] >= @min_utility
        arr_extensions_px = [] # mảng chứa các itemset thuộc phần mở rộng của itemset px
        @I.keys.each do |itemset_py|
          # duyêt các itemset py thuộc phần mở rộng của itemset px
          # điều kiện itemset py và cấu trúc eucs của pxy(x,y,c) sao cho c >= @min_utility
          if itemset_py != p && itemset_py != itemset_px && @arr_eucs[itemset_py => itemset_px] != nil && @arr_eucs[itemset_py => itemset_px] >= 0
            itemset_px_py = {} # xay dung utility cho p, px, py
            itemset_px_py[itemset_px] = itemset_py
            arr_extensions_px << itemset_px_py

            # itemset_px_py = []
            # itemset_px_py << itemset_px
            # itemset_px_py << itemset_py

            # arr_extensions_px << itemset_px
            # arr_extensions_px << itemset_py
            @utility_list_pxy = []
            binding.pry
            @utility_list_pxy << algorithm_3("3", itemset_px, itemset_py)
            # itemset_px_py[]
            # binding.pry
          end
        end
        # binding.pry
        algorithm_2(itemset_px, arr_extensions_px.uniq)
      end
    end
    binding.pry # lỗi đệ quy
  end
  # def algorithm_2(p, arr_extensions_p)
  #   arr_extensions_p.each do |itemset_px| # duyêt các itemset px thuộc phần mở rộng của itemset p
  #     # binding.pry
  #     if @arr_sum_utility_list[itemset_px].keys[0] >= @min_utility # điều kiên sum util trong danh sách hữu ích của px
  #       @arr_HUI[itemset_px] = @arr_sum_utility_list[itemset_px].keys[0] # xuất ra itemset là HUI
  #     end
  #     if @arr_sum_utility_list[itemset_px].keys[0] + @arr_sum_utility_list[itemset_px].values[0] >= @min_utility
  #       arr_extensions_px = [] # mảng chứa các itemset thuộc phần mở rộng của itemset px
  #       @I.keys.each do |itemset_py|
  #         # duyêt các itemset py thuộc phần mở rộng của itemset px
  #         # điều kiện itemset py và cấu trúc eucs của pxy(x,y,c) sao cho c >= @min_utility
  #         if itemset_py != p && itemset_py != itemset_px && @arr_eucs[itemset_py => itemset_px] != nil && @arr_eucs[itemset_py => itemset_px] >= 0
  #           itemset_px_py = {} # xay dung utility cho p, px, py
  #           itemset_px_py[itemset_px] = itemset_py
  #           arr_extensions_px << itemset_px_py
  #           # itemset_px_py = []
  #           # itemset_px_py << itemset_px
  #           # itemset_px_py << itemset_py
  #           # arr_extensions_px << itemset_px
  #           # arr_extensions_px << itemset_py
  #           @utility_list_pxy = []
  #           binding.pry
  #           @utility_list_pxy << algorithm_3("3", itemset_px, itemset_py)
  #           # itemset_px_py[]
  #           # binding.pry
  #         end
  #       end
  #       # binding.pry
  #       algorithm_2(itemset_px, arr_extensions_px.uniq)
  #     end
  #   end
  #   binding.pry # lỗi đệ quy
  # end

  def utility_list_of_itemset(itemset) # tính danh sách hữu ích của một item
    utility_list_of_itemset = {}
    @arr_utility_list.each do |keys, values|
      if keys.has_key?(itemset)
        utility_list_of_itemset[keys] = values
      end
    end
    utility_list_of_itemset
  end

  def findElementWithTID(item, td)
  end

  def algorithm_3(p, itemset_px, itemset_py)
    utility_list_of_pxy = [] # mảng chứa các tuple của danh sách hữu ích của pxy
    utility_list_of_itemset("2").each do |ex| # duyệt các bộ ex thuộc danh sách hữu ích của itemset px
      utility_list_of_itemset("4").each do |ey| # duyệt các bộ ey thuộc danh sách hữu ích của itemset py
        # binding.pry
        if ex[0].values[0] == ey[0].values[0] # điều kiện ex.tid = ey.tid
          exy = {} # khai báo hash lưu giá trị có dạng {tid => {util=>rutil}}
          if utility_list_of_itemset(p) != nil # điều kiên danh sách hữu ích của itemset p khác rỗng
            utility_list_of_itemset(p).each do |p|
              if p[0].values[0] == ex[0].values[0] # duyêt các bộ e trong danh sách hữu ích của itemset p
                hash_util_ruil = {} # khai báo hash lưu giá trị có dạng {util=>rutil}
                hash_util_ruil[ex[1].keys[0] + ey[1].keys[0] - p[1].keys[0]] = ey[1].values[0]
                exy[ex[0].values[0]] = hash_util_ruil
              end
            end
          else # điều kiên danh sách hữu ích của p là rỗng
            hash_util_ruil = {}
            hash_util_ruil[ex[1].keys[0] + ey[1].keys[0]] = ey[1].values[0]
            exy[ex[0].values[0]] = hash_util_ruil
          end
          unless exy.empty? # loại bõ nhưng phần tử rỗng ra khỏi danh sách hữu ích
            utility_list_of_pxy << exy
          end
        end
      end
    end
    utility_list_of_pxy
    binding.pry
  end

  # def calculate_util_in_arr_td(p, arr_td) # tính tổng các ituil của item trong các giao dịch cho trước
  #   sum = 0
  #   arr_td.each do |td|
  #     sum += @arr_utility_list[p => td].keys[0]
  #   end
  #   sum
  # end

  # def calculate_util_rutil_in_arr_td(p, arr_td) # tính tổng các ituil của item trong các giao dịch cho trước
  #   sum = 0
  #   arr_td.each do |td|
  #     sum += @arr_tu[td - 1].to_i
  #   end
  #   sum
  # end

  # def extensions_arr_td(p)
  #   hash_extensions_arr_td = {}
  #   @arr_items.each_with_index do |arr_item, index|
  #     if arr_item.include?(p)
  #       arr_item.each do |item|
  #         if (item != p) && @I.has_key?(item)
  #           extensions_p << item
  #           @arr_utility_list[p => index + 1].keys[0]
  #         end
  #         if item == p
  #           arr_td << index + 1
  #         end
  #       end
  #       hash_extensions_arr_td[]
  #     end
  #   end
  # end

  # def algorithm_2_search(p)
  #   extensions_p = [] # mảng chứa các item mở rộng của p
  #   arr_td = [] # mảng chứa các giao dịch (chứa item đang xét)
  #   @arr_items.each_with_index do |arr_item, index|
  #     if arr_item.include?(p)
  #       arr_item.each do |item|
  #         if (item != p) && @I.has_key?(item)
  #           extensions_p << item
  #           @arr_utility_list[p => index + 1].keys[0]
  #         end
  #         if item == p
  #           arr_td << index + 1
  #         end
  #       end
  #     end
  #   end
  #   binding.pry
  #   extensions_p.uniq.each do |item|
  #     arr_td_item = []
  #     arr_td.each do |td|
  #       if @arr_utility_list.has_key?(item => td) && @arr_utility_list.has_key?(p => td)
  #         arr_td_item << td # mảng chứa các giao dịch của itemset( item và p)
  #       end
  #     end
  #     if calculate_util_in_arr_td(item, arr_td_item) >= @min_utility # tổng util của item (trong cac giao dich co chua item vs p) >= min_utility
  #       @arr_HUI[item] = calculate_util_in_arr_td(item, arr_td_item)
  #     end
  #     hash_p_item = {}
  #     if calculate_util_rutil_in_arr_td(item, arr_td_item) >= @min_utility # tổng util và rutil của item (trong các giao dịch có chứa item và p) >= min_utility
  #       # hash_p_item[item] = p
  #       # @arr_HUI[hash_p_item] = calculate_util_rutil_in_arr_td(item, arr_td_item)
  #       extensions_px = {}
  #     end
  #     binding.pry
  #     # if calculate_util_rutil_in_arr_td(item, arr_td_item) + calculate_util_rutil_in_arr_td(p, arr_td_item) >= @min_utility
  #     #   extension_of_px
  #     # end
  #   end
  #   # binding.pry
  # end
end

main = FHM.new
main.algorithm_1_FHM
# main.algorithm_2_search("4")
# main.calculate_util_in_arr_td("2", [1, 2, 5])
# main.calculate_util_rutil_in_arr_td("3", [1, 2, 3])
