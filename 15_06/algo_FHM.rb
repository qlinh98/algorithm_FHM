require "pry" # khai báo thư viện debug
require "objspace" # khai báo thư viện tính ram sử dụng
require "benchmark" # khai báo thư viện tính thời gian thực thi
# require "wrapper"

class Pair
  attr_accessor :item, :utility
  def initialize
    @item = 0
    @utility = 0
  end
end

class UtilityList
  def initialize(item)
    @item = item
    @sumIutils = 0
    @sumRutils = 0
    @elements = []
  end

  # /**
  # * Method to add an element to this utility list and update the sums at the same time.
  # */
  def addElement(element)
    @sumIutils += element.instance_variable_get(:@iutils)
    @sumRutils += element.instance_variable_get(:@rutils)
    @elements << element
  end

  # def utilityList(item)
  #   @item = item
  # end
end

class Element
  def initialize(tid, iutils, rutils)
    @tid = tid
    @iutils = iutils
    @rutils = rutils
  end
end

class FHM
  def initialize
    @itemsetBuffer = []
    # @itemsetBuffer = (0...200).map {|x| x = 0}
    # puts @itemsetBuffer
    # binding.pry
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
  end

  ENABLE_LA_PRUNE = true

  def runAlgorithm(input, min_utility) # đọc files du lieu txt
    begin
      # arr_items = []
      f = File.open(input, "r")
      f.each_line do |line|

        # t = Time.now
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
    rescue
      f.close
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
    listOfUtilityLists.sort! { |item1, item2| compareItems(item1.instance_variable_get(:@item), item2.instance_variable_get(:@item)) }
    # binding.pry
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
            # revisedTransaction = []
            revisedTransaction = [] # // Create a list to store items
            for i in 0...items.length
              # /// convert values to integers
              # doi tuong chua item va utility tai 1 giao dich
              pair = Pair.new
              # pair.instance_variable_set(:@item, items[i].to_i)
              # pair.instance_variable_set(:@utility, utilityValues[i].to_i)
              pair.item = items[i].to_i
              pair.utility = utilityValues[i].to_i
              # binding.pry
              
              if @mapItemToTWU[pair.instance_variable_get(:@item)] >= min_utility
                # add it
                revisedTransaction << pair
                # remainingUtility += utilityValues[i].to_i
                # newTWU += utilityValues[i].to_i # new OPTIMIZATION
                remainingUtility += pair.instance_variable_get(:@utility)
                newTWU += pair.instance_variable_get(:@utility) # new OPTIMIZATION
              end
            end
            # sap xep tang dan tong hoa don (xem lai sap xep)
            revisedTransaction.sort! { |item1, item2| compareItems(item1.instance_variable_get(:@item), item2.instance_variable_get(:@item)) }
            for i in 0...revisedTransaction.length
              pair = revisedTransaction[i]
              # // subtract the utility of this item from the remaining utility
              remainingUtility = remainingUtility - pair.instance_variable_get(:@utility)
              # binding.pry
              # // get the utility list of this item
              utilityListOfItem = mapItemToUtilityList[pair.instance_variable_get(:@item)]
              # binding.pry

              # // Add a new Element to the utility list of this item corresponding to this
              # // transaction
              element = Element.new(tid, pair.instance_variable_get(:@utility), remainingUtility)
              utilityListOfItem.addElement(element)
              # binding.pry
              # // BEGIN NEW OPTIMIZATION for FHM
              mapFMAPItem = @mapFMAP[pair.instance_variable_get(:@item)]
              if mapFMAPItem.nil?
                mapFMAPItem = {}
                @mapFMAP[pair.instance_variable_get(:@item)] = mapFMAPItem
              end
              # binding.pry
              for j in i + 1...revisedTransaction.length
                pairAfter = revisedTransaction[j]
                twuSum = mapFMAPItem[pairAfter.instance_variable_get(:@item)]
                # mapFMAPItem = mapFMAPItem.sort.to_h
                # binding.pry
                if twuSum.nil?
                  mapFMAPItem[pairAfter.instance_variable_get(:@item)] = newTWU
                  # mapFMAPItem = mapFMAPItem.sort.to_h
                  # mapFMAPItem.to_a.sort!.to_h
                  # binding.pry
                else
                  mapFMAPItem[pairAfter.instance_variable_get(:@item)] = newTWU + twuSum
                end
                #sap xep
                # binding.pry
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
    binding.pry # toi day
  end

  def compareItems(item1, item2)
    # binding.pry
    compare = @mapItemToTWU[item1] - @mapItemToTWU[item2]
    compare == 0 ? item1 - item2 : compare
  end

  # /**
  #  * This is the recursive method to find all high utility itemsets. It writes the
  #  * itemsets to the output file.
  #  *
  #  * @param prefix       This is the current prefix. Initially, it is empty.
  #  * @param pUL          This is the Utility List of the prefix. Initially, it is
  #  *                     empty.
  #  * @param ULs          The utility lists corresponding to each extension of the
  #  *                     prefix.
  #  * @param minUtility   The minUtility threshold.
  #  * @param prefixLength The current prefix length
  #  * @throws IOException
  #  */

  def fhm(prefix, prefixLength, pUL, uls, min_utility)
    begin
      # // For each extension X of prefix P
      for i in 0...uls.length
        x = uls[i]
        # // If pX is a high utility itemset.
        # // we save the itemset: pX
        # binding.pry
        if x.instance_variable_get(:@sumIutils) >= min_utility
          # // save to file
          writeOut(prefix, prefixLength, x.instance_variable_get(:@item), x.instance_variable_get(:@sumIutils))
        end
        # // If the sum of the remaining utilities for pX
        # // is higher than minUtility, we explore extensions of pX.
        # // (this is the pruning condition)
        if x.instance_variable_get(:@sumIutils) + x.instance_variable_get(:@sumRutils) >= min_utility
          # // This list will contain the utility lists of pX extensions.
          exULs = []
          # // For each extension of p appearing
          # // after X according to the ascending order
          for j in i + 1...uls.length
            y = uls[j]
            # // ======================== NEW OPTIMIZATION USED IN FHM
            # binding.pry
            mapTWUF = @mapFMAP[x.instance_variable_get(:@item)]
            if !mapTWUF.nil?
              # binding.pry
              twuF = mapTWUF[y.instance_variable_get(:@item)]
              # binding.pry
              if twuF.nil? || twuF < min_utility
                next
              end
            end
            @candidateCount += 1
            # // =========================== END OF NEW OPTIMIZATION

            # // we construct the extension pXY
            # // and add it to the list of extensions of pX
            # binding.pry
            !(temp = construct(pUL, x, y, min_utility)).nil? ? exULs << temp : false
            # temp = construct(pUL, x, y, min_utility)
            # binding.pry
            # if !temp.nil?
            # exULs << temp
            # end
          end
          @dem += 1
          puts @dem
          # // We create new prefix pX
          @itemsetBuffer[prefixLength] = x.instance_variable_get(:@item)
          fhm(@itemsetBuffer, prefixLength + 1, x, exULs, min_utility)
        end
      end
    rescue
      puts "Lỗi rồi !!!"
    end
  end

  # /**
  #  * This method constructs the utility list of pXY
  #  *
  #  * @param P  : the utility list of prefix P.
  #  * @param px : the utility list of pX
  #  * @param py : the utility list of pY
  #  * @return the utility list of pXY
  #  */
  def construct(p, px, py, min_utility)
    # // create an empy utility list for pXY
    pxyUL = UtilityList.new(py.instance_variable_get(:@item))
    # // == new optimization - LA-prune == /
    # // Initialize the sum of total utility
    totalUtility = px.instance_variable_get(:@sumIutils) + px.instance_variable_get(:@sumRutils)
    # // ================================================
    # // for each element in the utility list of pX
    px.instance_variable_get(:@elements).each do |ex|
      # // do a binary search to find element ey in py with tid = ex.tid
      ex_tid = ex.instance_variable_get(:@tid)
      ex_iutils = ex.instance_variable_get(:@iutils)
      ey = findElementWithTID(py, ex_tid)
      # binding.pry
      if ey.nil?
        # // == new optimization - LA-prune == /
        if ENABLE_LA_PRUNE
          totalUtility -= (ex_iutils + ex.instance_variable_get(:@rutils))
          if (totalUtility < min_utility)
            return nil
          end
        end
        # // =============================================== /
        next
      end
      # // if the prefix p is null
      if p.nil?
        # // Create the new element
        eXY = Element.new(ex_tid, ex_iutils + ey.instance_variable_get(:@iutils), ey.instance_variable_get(:@rutils))
        # // add the new element to the utility list of pXY
        pxyUL.addElement(eXY)
        # binding.pry
      else
        # // find the element in the utility list of p wih the same tid
        e = findElementWithTID(p, ex_tid)
        # binding.pry
        if !e.nil?
          # binding.pry
          # // Create new element
          eXY = Element.new(ex_tid, ex_iutils + ey.instance_variable_get(:@iutils) - e.instance_variable_get(:@iutils), ey.instance_variable_get(:@rutils))
          # // add the new element to the utility list of pXY
          pxyUL.addElement(eXY)
        end
      end
    end
    # // return the utility list of pXY.
    pxyUL
    # binding.pry
  end

  # /**
  # * Do a binary search to find the element with a given tid in a utility list
  # *
  # * @param ulist the utility list
  # * @param tid   the tid
  # * @return the element or null if none has the tid.
  # */
  def findElementWithTID(ulist, tid)
    list = ulist.instance_variable_get(:@elements)
    # // perform a binary search to check if the subset appears in level k-1.
    first = 0
    last = list.length - 1
    # // the binary search
    while first <= last
      # // divide by 2
      # middle = (first + last) >> 1
      middle = (first + last) / 2
      list_middle = list[middle].instance_variable_get(:@tid)
      if list_middle < tid
        # // the itemset compared is larger than the subset according to the lexical order
        first = middle + 1
      elsif list_middle > tid
        # // the itemset compared is smaller than the subset is smaller according to the
        # // lexical order
        last = middle - 1
      else
        return list[middle]
      end
    end
  end

  # /**
  # * Method to write a high utility itemset to the output file.
  # *
  # * @param the          prefix to be writent o the output file
  # * @param an           item to be appended to the prefix
  # * @param utility      the utility of the prefix concatenated with the item
  # * @param prefixLength the prefix length
  # */
  def writeOut(prefix, prefixLength, item, utility)
    # // increase the number of high utility itemsets found
    @huiCount += 1
    #  // Create a string buffer
    # buffer = StringBuilder.new
    # binding.pry
    # buffer = String.buffer(20)
    # binding.pry
    buffer = []
    #  // append the prefix
    for i in 0...prefixLength
      # buffer.append(prefix[i])
      # buffer.append(" ")
      buffer << prefix[i]
    end
    #  // append the last item
    # buffer.append(item)
    buffer << item
    @hash_HUI[buffer] = utility
    # binding.pry
    # #  // append the utility value
    # buffer.append(" #UTIL: ")
    # buffer.append(utility)
    # #  // write to file
    # #  writer.write(buffer.toString())
    # #  writer.newLine()
    # #  ///////////////////
    # println (buffer.to_s)
  end
end

main = FHM.new
# input = "./DB_Utility.txt"
# min_utility = 30
input = "./BMS_utility_spmf1.txt"
min_utility = 2268000
# input = "./chainstore.txt"
# min_utility = 2600000
Benchmark.bm(5) do |x|
  x.report("-----> Times hoan tat tim kiem: \n") {
    main.runAlgorithm(input, min_utility)
  }
end
