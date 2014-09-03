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
      print "Enter new PW for #{args[2]}: "
      pw0 = STDIN.noecho(&:gets).chomp
      print "\nRetype new PW for #{args[2]} :"
      pw1 = STDIN.noecho(&:gets).chomp
      print "\n"
      if pw0==pw1
        add_pw args[2], pw0
        puts 'New PW added'
      else
        puts 'Passwords do not match!'
      end
    when '-d'
    else
      pw =  get_pw args[1]
      if args[2]=='-p'
        puts pw
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
  puts file
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
  rescue 
    puts "Wrong PW?"
    exit 0
  end
end

def create_cipher
  cipher = OpenSSL::Cipher::AES.new(256, :CBC)
end

if __FILE__ == $0
  main ARGV.dup
end
