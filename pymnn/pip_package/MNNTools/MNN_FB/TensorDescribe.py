# automatically generated by the FlatBuffers compiler, do not modify

# namespace: MNN

import flatbuffers

class TensorDescribe(object):
    __slots__ = ['_tab']

    @classmethod
    def GetRootAsTensorDescribe(cls, buf, offset):
        n = flatbuffers.encode.Get(flatbuffers.packer.uoffset, buf, offset)
        x = TensorDescribe()
        x.Init(buf, n + offset)
        return x

    # TensorDescribe
    def Init(self, buf, pos):
        self._tab = flatbuffers.table.Table(buf, pos)

    # TensorDescribe
    def Blob(self):
        o = flatbuffers.number_types.UOffsetTFlags.py_type(self._tab.Offset(4))
        if o != 0:
            x = self._tab.Indirect(o + self._tab.Pos)
            from .Blob import Blob
            obj = Blob()
            obj.Init(self._tab.Bytes, x)
            return obj
        return None

    # TensorDescribe
    def Index(self):
        o = flatbuffers.number_types.UOffsetTFlags.py_type(self._tab.Offset(6))
        if o != 0:
            return self._tab.Get(flatbuffers.number_types.Int32Flags, o + self._tab.Pos)
        return 0

    # TensorDescribe
    def Name(self):
        o = flatbuffers.number_types.UOffsetTFlags.py_type(self._tab.Offset(8))
        if o != 0:
            return self._tab.String(o + self._tab.Pos)
        return None

def TensorDescribeStart(builder): builder.StartObject(3)
def TensorDescribeAddBlob(builder, blob): builder.PrependUOffsetTRelativeSlot(0, flatbuffers.number_types.UOffsetTFlags.py_type(blob), 0)
def TensorDescribeAddIndex(builder, index): builder.PrependInt32Slot(1, index, 0)
def TensorDescribeAddName(builder, name): builder.PrependUOffsetTRelativeSlot(2, flatbuffers.number_types.UOffsetTFlags.py_type(name), 0)
def TensorDescribeEnd(builder): return builder.EndObject()