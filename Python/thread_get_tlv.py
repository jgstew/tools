# from: https://www.reddit.com/r/homeassistant/comments/11pkmpu/comment/jzjtxbo
import python_otbr_api
from python_otbr_api import PENDING_DATASET_DELAY_TIMER, tlv_parser
from python_otbr_api.pskc import compute_pskc
from python_otbr_api.tlv_parser import MeshcopTLVItem, MeshcopTLVType

# Apple
CHANNEL = 25

PANID = "aaaa"
EXTPANID = "aaaaaaaaaaaaaa"
# 16-byte network key
# (hexadecimal representation)
# This is a placeholder key; replace it with your actual network key.
NETWORK_KEY = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
# 8-byte timestamp
# (hexadecimal representation)
TIMESTAMP = b"\x00\x00\x00\x00\x00\x03\x00\x00"

channel = MeshcopTLVItem(tag=0, data=CHANNEL.to_bytes(length=3, byteorder="big"))
pan_id = MeshcopTLVItem(tag=1, data=bytes.fromhex(PANID))
ext_pan_id = MeshcopTLVItem(tag=2, data=bytes.fromhex(EXTPANID))
network_key = MeshcopTLVItem(tag=5, data=bytes.fromhex(NETWORK_KEY))
timestamp = MeshcopTLVItem(tag=14, data=TIMESTAMP)

tlv_new = {0: channel, 1: pan_id, 2: ext_pan_id, 4: network_key, 14: timestamp}
tlv = tlv_parser.encode_tlv(tlv_new)
print(tlv)
