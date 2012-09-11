class ApplicationController < ActionController::Base
  protect_from_forgery
  
  def arr_to_hash(a)
      hash = {}
      for i in 0..a.length-1
          hash[i.to_s] = a[i]
      end
      hash
  end
  
  def clean_hash( hash )
   hash.each do |k,v|
    hash[k] = arr_to_hash v if v.is_a?( Array ) && v.count > 1
    hash[k] = v.first if v.is_a?( Array ) && v.count == 1
    clean_it( hash[k] ) if hash[k].is_a?( Hash )
   end
  end  
end
