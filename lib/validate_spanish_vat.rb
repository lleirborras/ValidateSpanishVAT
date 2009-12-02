module ValidateSpanishVat
  module ClassMethods
    # Implements model level validator for Spanish's VAT number.
    # Usage: 
    #
    # Inside a model with a vat field, simply put
    #
    #   validates_spanish_vat field_name
    #
    def validates_spanish_vat(*attr_names)
      configuration = { :message => 'is invalid', :on => :save }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      
      validates_each(attr_names, configuration) do |record, attr_name, value|
        record.errors.add(attr_name, configuration[:message]) unless CustomValidator::SpanishVAT.validate(String.new(value)) unless value.nil?
      end
    end
  end
end

module CustomValidator
  class SpanishVAT
    # Main validate function, it runs several regexp's to determine if value is a nif, cif or nie.
    # If so, it runs specific test, else fails
    def self.validate(value)
      case
        when value.match(/[0-9]{8}[a-z]/i)
          return validate_nif(value)
        when value.match(/[a-wyz][0-9]{7}[0-9a-z]/i)
          return validate_cif(value)
        when value.match(/[x][0-9]{7,8}[a-z]/i)
          return validate_nie(value)
      end
      return false
    end

    # Validates NIF
    def self.validate_nif(value)
      letters = "TRWAGMYFPDXBNJZSQVHLCKE"
      check = value.slice!(value.length - 1..value.length - 1).upcase
      calculated_letter = letters[value.to_i % 23].chr
      return check === calculated_letter
    end

    # Validates CIF
    def self.validate_cif(value)
      pares = 0
      impares = 0
      uletra = ["J", "A", "B", "C", "D", "E", "F", "G", "H", "I"]
      texto = value.upcase
      regular = /^[ABCDEFGHKLMNPQRS]\d{7}[0-9,A-J]$/#g);
      if regular.match(value).blank?
        false 
      else
        ultima = texto[8,1]

        [1,3,5,7].collect do |cont|
          xxx = (2 * texto[cont,1].to_i).to_s + "0"
          impares += xxx[0,1].to_i + xxx[1,1].to_i
          pares += texto[cont+1,1].to_i
        end

        xxx = (2 * texto[8,1].to_i).to_s + "0"
        impares += xxx[0,1].to_i + xxx[1,1].to_i
         
        suma = (pares + impares).to_s
        unumero = suma.last.to_i
        unumero = (10 - unumero).to_s
        unumero = 0 if(unumero == 10)
         
        ((ultima == unumero) || (ultima == uletra[unumero.to_i]))
      end
    end

    # Validates NIE, in fact is a fake, a NIE is really a NIF with first number changed to capital 'X' letter, so we change the first X to a 0 and then try to
    # pass the nif validator
    def self.validate_nie(value)
      value[0] = '0'
      value.slice(0) if value.size > 9
      validate_nif(value)
    end
  end
end
