from rchain.crypto import PrivateKey
import sys

if __name__ == "__main__":
	i = int(sys.argv[1])
	while i > 0:
		sk = PrivateKey.generate()
		pk = sk.get_public_key()
		w = pk.get_rev_address()
		print(sk.to_hex(), pk.to_hex(), w)
		i-=1
