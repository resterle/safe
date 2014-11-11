require 'openssl'
require 'io/console'
require 'json'
require 'clipboard'

def main args
  @iv = '07FfuoxMNawSnYTpv8FUI699d1O6ATRX6j32feJt'
  @key = create_pwkey
  @file = args[0]
  decrypt_keys
  case args[1]
    when '-c'
      key = args[2]
      if @data.has_key? key
        puts 'PW for this key already exists!'
        exit 0
      end
      add_pw key, get_new_pw(key)
      puts 'New PW added'
    when '-l'
      puts 'keys:'
      @data.keys.each do |key|
        puts " #{key}"
      end
    else
      pw =  get_pw args[1]
      if args[2]=='-p'
        puts "\n#{pw}\nYou should close this window now!"
      else
        Clipboard.copy pw
     end
  end 
  write @file
end

def create_pwkey( prompt='Master password: ')
  print prompt 
  OpenSSL::PKCS5.pbkdf2_hmac_sha1( STDIN.noecho(&:gets).chomp, 'hc4dpx5fav', 2487, 512)
end

def read file
  File.open(file, 'r+'){|f|
    raw = f.read
    if raw!=''
      @data = JSON.parse decrypt(raw)
    else
      {}
    end
  }
end

def write file
  File.open(file, 'w'){ |f|
    f.write encrypt(JSON.dump @data)
  }
end 

def decrypt_keys
  @data = read @file
end

def add_pw key, val
  @data[key] = val
end

def get_pw key
  @data[key]
end

def decrypt encrypted
  cipher = create_cipher
  cipher.decrypt
  update cipher, encrypted
end

def encrypt data
  cipher = create_cipher
  cipher.encrypt
  update cipher, data
end

def update cipher, data
  cipher.key = @key
  cipher.iv = @iv
  begin 
    cipher.update(data) + cipher.final
  rescue Exception => e 
    puts "Wrong PW? #{e}"
    exit 0
  end
end

def create_cipher
  cipher = OpenSSL::Cipher::AES.new(256, :CBC)
end

def get_new_pw key
      print "\nEnter new PW for #{key}: "
      pw0 = STDIN.noecho(&:gets).chomp
      print "\nRetype new PW for #{key} :"
      pw1 = STDIN.noecho(&:gets).chomp
      print "\n"
      if pw0==pw1
        return pw0
      else
        puts 'Passwords do not match!'
	exit 0
      end
end
if __FILE__ == $0
  main ARGV.dup
end
