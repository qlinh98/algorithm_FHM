require "pry" # khai báo thư viện debug
require "benchmark" # khai báo thư viện tính thời gian thực thi

class Pair
  attr_accessor :item, :utility

  def initialize
    @item = 0
    @utility = 0
  end
end

# Pair = Struct.new(:item, :utility)
# Element = Struct.new(:tid, :iutils, :rutils)

class UtilityList
  attr_accessor :item, :sumIutils, :sumRutils, :elements

  def initialize(item)
    @item = item
    @sumIutils = 0
    @sumRutils = 0
    @elements = []
  end

  def addElement(element)
    @sumIutils += element.iutils
    @sumRutils += element.rutils
    @elements << element
  end
end

class Element
  attr_accessor :tid, :iutils, :rutils

  def initialize(tid, iutils, rutils)
    @tid = tid
    @iutils = iutils
    @rutils = rutils
  end
end

class FHM
  def initialize
    @itemsetBuffer = []
    # (1...200).each { |x| @itemsetBuffer << 0 }
    @arr_HUI = []
    # /** The eucs structure: key: item key: another item value: twu */
    @mapFMAP = {}
    # /** Map to remember the TWU of each item */
    @mapItemToTWU = {}
    # /** the number of candidate high-utility itemsets */
    @candidateCount = 0
    # /** the number of high-utility itemsets generated */
    @huiCount = 0
    # chua danh sach huu ich
    @hash_HUI = {}
    @dem = 0
    # @mapFMAP = OpenStruct.new
  end

  ENABLE_LA_PRUNE = true

  def runAlgorithm(input, min_utility) # đọc files du lieu txt
    f = File.open(input, "r")
    f.each_line do |line|
      if !line.gsub("\r\n", "").empty?
        # // split the transaction according to the : separator
        split = line.split(":")
        # // the first part is the list of items
        items = split[0].split(" ")
        transactionUtility = split[1].to_i
        for i in 0...items.length
          item = items[i].to_i
          # @mapItemToTWU[item].nil? ? twu = transactionUtility : twu = @mapItemToTWU[item] + transactionUtility
          twu = @mapItemToTWU[item]
          twu = (twu.nil?) ? transactionUtility : twu + transactionUtility
          @mapItemToTWU[item] = twu
        end
      end
    end
    # tinh twu cua tung item va sap xep tang dan
    @mapItemToTWU = @mapItemToTWU.sort.to_h
    # khai bao mang chua: item, element, sumUtil, sumRutil
    listOfUtilityLists = []
    # khai bao hash chua: keys: item; values: item, element, sumUtil, sumRutil
    mapItemToUtilityList = {}
    # duyet key cua hash chua item voi twu
    @mapItemToTWU.each_key do |item|
      if @mapItemToTWU[item] >= min_utility
        uList = UtilityList.new(item)
        mapItemToUtilityList[item] = uList
        listOfUtilityLists << uList
      end
    end
    listOfUtilityLists.sort! { |item1, item2| compareItems(item1.item, item2.item) }
    time = Benchmark.realtime do
      # duyet csdl lan 2 de tinh utilitylist va sap xem tang dan theo theo twu
      begin
        f = File.open(input, "r")
        tid = 0
        f.each_line do |line|
          if !line.gsub("\r\n", "").empty?
            # // split the line according to the separator
            split = line.gsub("\r\n", "").split(":")
            # // get the list of items
            items = split[0].split(" ")
            utilityValues = split[2].split(" ") # magng chua cac util tuong ung voi cac item.
            # // Copy the transaction into lists but
            # // without items with TWU < minutility
            remainingUtility = 0
            newTWU = 0    #// NEW OPTIMIZATION
            revisedTransaction = [] # // Create a list to store items
            items.each_with_index do |item, i|
              # /// convert values to integers
              # doi tuong chua item va utility tai 1 giao dich
              pair = Pair.new
              pair.item = item.to_i
              pair.utility = utilityValues[i].to_i
              if @mapItemToTWU[pair.item] >= min_utility
                # add it
                revisedTransaction << pair
                remainingUtility += pair.utility
                newTWU += pair.utility # new OPTIMIZATION
              end
            end
            # sap xep tang dan tong hoa don (xem lai sap xep)
            revisedTransaction.sort! { |item1, item2| compareItems(item1.item, item2.item) }
            # for i in 0...revisedTransaction.length
            revisedTransaction.each_with_index do |revisedTransaction_i, i|
              pair = revisedTransaction_i
              # // subtract the utility of this item from the remaining utility
              # remainingUtility = remainingUtility - pair.utility
              remainingUtility -= pair.utility
              # // get the utility list of this item
              utilityListOfItem = mapItemToUtilityList[pair.item]
              # // Add a new Element to the utility list of this item corresponding to this
              # // transaction
              element = Element.new(tid, pair.utility, remainingUtility)
              utilityListOfItem.addElement(element)
              # binding.pry
              # // BEGIN NEW OPTIMIZATION for FHM
              @mapFMAP[pair.item] = {} if @mapFMAP[pair.item].nil?
              mapFMAPItem = @mapFMAP[pair.item]
              # for j in i + 1...revisedTransaction.length
              revisedTransaction[i + 1...revisedTransaction.length].each do |revisedTransaction_j|
                # pairAfter = revisedTransaction_j
                # binding.pry
                # twuSum = mapFMAPItem[pairAfter.item]
                # if twuSum.nil?
                #   mapFMAPItem[pairAfter.item] = newTWU
                # else
                #   mapFMAPItem[pairAfter.item] = newTWU + twuSum
                # end
                # binding.pry
                mapFMAPItem[revisedTransaction_j.item].nil? ? mapFMAPItem[revisedTransaction_j.item] = newTWU : mapFMAPItem[revisedTransaction_j.item] += newTWU
              end
              # // END OPTIMIZATION of FHM
            end
          else
            next
          end
          tid += 1
          # [[@mapFMAP.keys.first,@mapFMAP.values.first.sort.to_h]].sort.to_h
        end
      rescue
        f.close
      end
    end
    @mapFMAP = @mapFMAP.sort.to_h
    # binding.pry
    puts "Time test: #{time.round(7)}"
    puts "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
    # endTimestamp = (Time.now.to_f * 1000).floor
    # p "Time test: #{endTimestamp - startTimestamp}"
    # binding.pry
    # itemsetBuffer = []
    Benchmark.bm(5) do |x|
      x.report("-----> Times hoan tat tim kiem: ") {
        fhm(@itemsetBuffer, 0, nil, listOfUtilityLists, min_utility)
      }
    end
    puts "#{@hash_HUI}: #{@hash_HUI.length}"
    puts "%d MB" % (`ps -o rss= -p #{Process.pid}`.to_i / 1024)
    binding.pry # toi day
  end

  def compareItems(item1, item2)
    compare = @mapItemToTWU[item1] - @mapItemToTWU[item2]
    compare == 0 ? item1 - item2 : compare
  end

  def fhm(prefix, prefixLength, pUL, uls, min_utility)
    uls.each_with_index do |x, i|
      if x.sumIutils >= min_utility
        writeOut(prefix, prefixLength, x.item, x.sumIutils)
      end
      if x.sumIutils + x.sumRutils >= min_utility
        exULs = []
        uls[i + 1...uls.length].each do |y|
          # mapTWUF = @mapFMAP[x.item]
          # next if !mapTWUF.nil? && ((twuF = mapTWUF[y.item]).nil? || (twuF = mapTWUF[y.item]) < min_utility)
          next if !@mapFMAP[x.item].nil? && ((@mapFMAP[x.item][y.item]).nil? || (@mapFMAP[x.item][y.item]) < min_utility)
          # @candidateCount += 1
          # binding.pry
          temp = construct(pUL, x, y, min_utility)
          if !temp.nil?
            exULs << temp
          end
        end
        @dem += 1
        puts @dem
        @itemsetBuffer[prefixLength] = x.item
        fhm(@itemsetBuffer, prefixLength + 1, x, exULs, min_utility)
      end
    end
  end

  def construct(p, px, py, min_utility)
    # // create an empy utility list for pXY
    pxyUL = UtilityList.new(py.item)
    # // == new optimization - LA-prune == /
    # // Initialize the sum of total utility
    totalUtility = px.sumIutils + px.sumRutils
    # // ================================================
    # // for each element in the utility list of pX
    px.elements.each do |ex|
      # // do a binary search to find element ey in py with tid = ex.tid
      ey = findElementWithTID(py, ex.tid)
      if ey.nil?
        # // == new optimization - LA-prune == /
        return nil if (totalUtility -= (ex.iutils + ex.rutils)) < min_utility
        # // =============================================== /
        next
      end
      # // if the prefix p is null
      if p.nil?
        # // Create the new element
        eXY = Element.new(ex.tid, ex.iutils + ey.iutils, ey.rutils)
        # // add the new element to the utility list of pXY
        pxyUL.addElement(eXY)
      else
        # // find the element in the utility list of p wih the same tid
        e = findElementWithTID(p, ex.tid)
        if !e.nil?
          # // Create new element
          eXY = Element.new(ex.tid, ex.iutils + ey.iutils - e.iutils, ey.rutils)
          # // add the new element to the utility list of pXY
          pxyUL.addElement(eXY)
        end
      end
    end
    # // return the utility list of pXY.
    pxyUL
  end

  def findElementWithTID(ulist, tid)
    list = ulist.elements
    # // perform a binary search to check if the subset appears in level k-1.
    first = 0
    last = list.length - 1
    # // the binary search
    while first <= last
      # // divide by 2
      # middle = (first + last) >> 1
      middle = (first + last) / 2
      if list[middle].tid < tid
        # // the itemset compared is larger than the subset according to the lexical order
        first = middle + 1
      elsif list[middle].tid > tid
        # // the itemset compared is smaller than the subset is smaller according to the
        # // lexical order
        last = middle - 1
      else
        return list[middle]
      end
    end
  end

  def writeOut(prefix, prefixLength, item, utility)
    # // increase the number of high utility itemsets found
    @huiCount += 1
    buffer = []
    for i in 0...prefixLength
      buffer << prefix[i]
    end
    buffer << item
    @hash_HUI[buffer] = utility
  end
end

main = FHM.new
# input = "./DB_Utility.txt"
# min_utility = 30
# input = "./BMS_utility_spmf1.txt"
# min_utility = 2268000
input = "./chainstore.txt"
min_utility = 2600000
Benchmark.bm(5) do |x|
  x.report("-----> Times hoan tat tim kiem: \n") {
    main.runAlgorithm(input, min_utility)
  }
end
