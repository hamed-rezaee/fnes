import 'package:fnes/components/bus.dart';
import 'package:fnes/components/emulator_state.dart';

class CPU {
  CPU() {
    lookup[0x00] = Instruction(InstructionType.brk, AddressMode.imp, 7);
    lookup[0x01] = Instruction(InstructionType.ora, AddressMode.izx, 6);
    lookup[0x02] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0x03] = Instruction(InstructionType.slo, AddressMode.izx, 8);
    lookup[0x04] = Instruction(InstructionType.nop, AddressMode.zp0, 3);
    lookup[0x05] = Instruction(InstructionType.ora, AddressMode.zp0, 3);
    lookup[0x06] = Instruction(InstructionType.asl, AddressMode.zp0, 5);
    lookup[0x07] = Instruction(InstructionType.slo, AddressMode.zp0, 5);
    lookup[0x08] = Instruction(InstructionType.php, AddressMode.imp, 3);
    lookup[0x09] = Instruction(InstructionType.ora, AddressMode.imm, 2);
    lookup[0x0A] = Instruction(InstructionType.asl, AddressMode.imp, 2);
    lookup[0x0B] = Instruction(InstructionType.anc, AddressMode.imm, 2);
    lookup[0x0C] = Instruction(InstructionType.nop, AddressMode.abs, 4);
    lookup[0x0D] = Instruction(InstructionType.ora, AddressMode.abs, 4);
    lookup[0x0E] = Instruction(InstructionType.asl, AddressMode.abs, 6);
    lookup[0x0F] = Instruction(InstructionType.slo, AddressMode.abs, 6);
    lookup[0x10] = Instruction(InstructionType.bpl, AddressMode.rel, 2);
    lookup[0x11] = Instruction(InstructionType.ora, AddressMode.izy, 5);
    lookup[0x12] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x13] = Instruction(InstructionType.slo, AddressMode.izy, 8);
    lookup[0x14] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0x15] = Instruction(InstructionType.ora, AddressMode.zpx, 4);
    lookup[0x16] = Instruction(InstructionType.asl, AddressMode.zpx, 6);
    lookup[0x17] = Instruction(InstructionType.slo, AddressMode.zpx, 6);
    lookup[0x18] = Instruction(InstructionType.clc, AddressMode.imp, 2);
    lookup[0x19] = Instruction(InstructionType.ora, AddressMode.aby, 4);
    lookup[0x1A] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x1B] = Instruction(InstructionType.slo, AddressMode.aby, 7);
    lookup[0x1C] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0x1D] = Instruction(InstructionType.ora, AddressMode.abx, 4);
    lookup[0x1E] = Instruction(InstructionType.asl, AddressMode.abx, 7);
    lookup[0x1F] = Instruction(InstructionType.slo, AddressMode.abx, 7);
    lookup[0x20] = Instruction(InstructionType.jsr, AddressMode.abs, 6);
    lookup[0x21] = Instruction(InstructionType.and, AddressMode.izx, 6);
    lookup[0x22] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0x23] = Instruction(InstructionType.rla, AddressMode.izx, 8);
    lookup[0x24] = Instruction(InstructionType.bit, AddressMode.zp0, 3);
    lookup[0x25] = Instruction(InstructionType.and, AddressMode.zp0, 3);
    lookup[0x26] = Instruction(InstructionType.rol, AddressMode.zp0, 5);
    lookup[0x27] = Instruction(InstructionType.rla, AddressMode.zp0, 5);
    lookup[0x28] = Instruction(InstructionType.plp, AddressMode.imp, 4);
    lookup[0x29] = Instruction(InstructionType.and, AddressMode.imm, 2);
    lookup[0x2A] = Instruction(InstructionType.rol, AddressMode.imp, 2);
    lookup[0x2B] = Instruction(InstructionType.anc, AddressMode.imm, 2);
    lookup[0x2C] = Instruction(InstructionType.bit, AddressMode.abs, 4);
    lookup[0x2D] = Instruction(InstructionType.and, AddressMode.abs, 4);
    lookup[0x2E] = Instruction(InstructionType.rol, AddressMode.abs, 6);
    lookup[0x2F] = Instruction(InstructionType.rla, AddressMode.abs, 6);
    lookup[0x30] = Instruction(InstructionType.bmi, AddressMode.rel, 2);
    lookup[0x31] = Instruction(InstructionType.and, AddressMode.izy, 5);
    lookup[0x32] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x33] = Instruction(InstructionType.rla, AddressMode.izy, 8);
    lookup[0x34] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0x35] = Instruction(InstructionType.and, AddressMode.zpx, 4);
    lookup[0x36] = Instruction(InstructionType.rol, AddressMode.zpx, 6);
    lookup[0x37] = Instruction(InstructionType.rla, AddressMode.zpx, 6);
    lookup[0x38] = Instruction(InstructionType.sec, AddressMode.imp, 2);
    lookup[0x39] = Instruction(InstructionType.and, AddressMode.aby, 4);
    lookup[0x3A] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x3B] = Instruction(InstructionType.rla, AddressMode.aby, 7);
    lookup[0x3C] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0x3D] = Instruction(InstructionType.and, AddressMode.abx, 4);
    lookup[0x3E] = Instruction(InstructionType.rol, AddressMode.abx, 7);
    lookup[0x3F] = Instruction(InstructionType.rla, AddressMode.abx, 7);
    lookup[0x40] = Instruction(InstructionType.rti, AddressMode.imp, 6);
    lookup[0x41] = Instruction(InstructionType.eor, AddressMode.izx, 6);
    lookup[0x42] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0x43] = Instruction(InstructionType.sre, AddressMode.izx, 8);
    lookup[0x44] = Instruction(InstructionType.nop, AddressMode.zp0, 3);
    lookup[0x45] = Instruction(InstructionType.eor, AddressMode.zp0, 3);
    lookup[0x46] = Instruction(InstructionType.lsr, AddressMode.zp0, 5);
    lookup[0x47] = Instruction(InstructionType.sre, AddressMode.zp0, 5);
    lookup[0x48] = Instruction(InstructionType.pha, AddressMode.imp, 3);
    lookup[0x49] = Instruction(InstructionType.eor, AddressMode.imm, 2);
    lookup[0x4A] = Instruction(InstructionType.lsr, AddressMode.imp, 2);
    lookup[0x4B] = Instruction(InstructionType.alr, AddressMode.imm, 2);
    lookup[0x4C] = Instruction(InstructionType.jmp, AddressMode.abs, 3);
    lookup[0x4D] = Instruction(InstructionType.eor, AddressMode.abs, 4);
    lookup[0x4E] = Instruction(InstructionType.lsr, AddressMode.abs, 6);
    lookup[0x4F] = Instruction(InstructionType.sre, AddressMode.abs, 6);
    lookup[0x50] = Instruction(InstructionType.bvc, AddressMode.rel, 2);
    lookup[0x51] = Instruction(InstructionType.eor, AddressMode.izy, 5);
    lookup[0x52] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x53] = Instruction(InstructionType.sre, AddressMode.izy, 8);
    lookup[0x54] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0x55] = Instruction(InstructionType.eor, AddressMode.zpx, 4);
    lookup[0x56] = Instruction(InstructionType.lsr, AddressMode.zpx, 6);
    lookup[0x57] = Instruction(InstructionType.sre, AddressMode.zpx, 6);
    lookup[0x58] = Instruction(InstructionType.cli, AddressMode.imp, 2);
    lookup[0x59] = Instruction(InstructionType.eor, AddressMode.aby, 4);
    lookup[0x5A] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x5B] = Instruction(InstructionType.sre, AddressMode.aby, 7);
    lookup[0x5C] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0x5D] = Instruction(InstructionType.eor, AddressMode.abx, 4);
    lookup[0x5E] = Instruction(InstructionType.lsr, AddressMode.abx, 7);
    lookup[0x5F] = Instruction(InstructionType.sre, AddressMode.abx, 7);
    lookup[0x60] = Instruction(InstructionType.rts, AddressMode.imp, 6);
    lookup[0x61] = Instruction(InstructionType.adc, AddressMode.izx, 6);
    lookup[0x62] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0x63] = Instruction(InstructionType.rra, AddressMode.izx, 8);
    lookup[0x64] = Instruction(InstructionType.nop, AddressMode.zp0, 3);
    lookup[0x65] = Instruction(InstructionType.adc, AddressMode.zp0, 3);
    lookup[0x66] = Instruction(InstructionType.ror, AddressMode.zp0, 5);
    lookup[0x67] = Instruction(InstructionType.rra, AddressMode.zp0, 5);
    lookup[0x68] = Instruction(InstructionType.pla, AddressMode.imp, 4);
    lookup[0x69] = Instruction(InstructionType.adc, AddressMode.imm, 2);
    lookup[0x6A] = Instruction(InstructionType.ror, AddressMode.imp, 2);
    lookup[0x6B] = Instruction(InstructionType.arr, AddressMode.imm, 2);
    lookup[0x6C] = Instruction(InstructionType.jmp, AddressMode.ind, 5);
    lookup[0x6D] = Instruction(InstructionType.adc, AddressMode.abs, 4);
    lookup[0x6E] = Instruction(InstructionType.ror, AddressMode.abs, 6);
    lookup[0x6F] = Instruction(InstructionType.rra, AddressMode.abs, 6);
    lookup[0x70] = Instruction(InstructionType.bvs, AddressMode.rel, 2);
    lookup[0x71] = Instruction(InstructionType.adc, AddressMode.izy, 5);
    lookup[0x72] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x73] = Instruction(InstructionType.rra, AddressMode.izy, 8);
    lookup[0x74] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0x75] = Instruction(InstructionType.adc, AddressMode.zpx, 4);
    lookup[0x76] = Instruction(InstructionType.ror, AddressMode.zpx, 6);
    lookup[0x77] = Instruction(InstructionType.rra, AddressMode.zpx, 6);
    lookup[0x78] = Instruction(InstructionType.sei, AddressMode.imp, 2);
    lookup[0x79] = Instruction(InstructionType.adc, AddressMode.aby, 4);
    lookup[0x7A] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x7B] = Instruction(InstructionType.rra, AddressMode.aby, 7);
    lookup[0x7C] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0x7D] = Instruction(InstructionType.adc, AddressMode.abx, 4);
    lookup[0x7E] = Instruction(InstructionType.ror, AddressMode.abx, 7);
    lookup[0x7F] = Instruction(InstructionType.rra, AddressMode.abx, 7);
    lookup[0x80] = Instruction(InstructionType.nop, AddressMode.imm, 2);
    lookup[0x81] = Instruction(InstructionType.sta, AddressMode.izx, 6);
    lookup[0x82] = Instruction(InstructionType.nop, AddressMode.imm, 2);
    lookup[0x83] = Instruction(InstructionType.sax, AddressMode.izx, 6);
    lookup[0x84] = Instruction(InstructionType.sty, AddressMode.zp0, 3);
    lookup[0x85] = Instruction(InstructionType.sta, AddressMode.zp0, 3);
    lookup[0x86] = Instruction(InstructionType.stx, AddressMode.zp0, 3);
    lookup[0x87] = Instruction(InstructionType.sax, AddressMode.zp0, 3);
    lookup[0x88] = Instruction(InstructionType.dey, AddressMode.imp, 2);
    lookup[0x89] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0x8A] = Instruction(InstructionType.txa, AddressMode.imp, 2);
    lookup[0x8B] = Instruction(InstructionType.xaa, AddressMode.imm, 2);
    lookup[0x8C] = Instruction(InstructionType.sty, AddressMode.abs, 4);
    lookup[0x8D] = Instruction(InstructionType.sta, AddressMode.abs, 4);
    lookup[0x8E] = Instruction(InstructionType.stx, AddressMode.abs, 4);
    lookup[0x8F] = Instruction(InstructionType.sax, AddressMode.abs, 4);
    lookup[0x90] = Instruction(InstructionType.bcc, AddressMode.rel, 2);
    lookup[0x91] = Instruction(InstructionType.sta, AddressMode.izy, 6);
    lookup[0x92] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0x93] = Instruction(InstructionType.ahx, AddressMode.izy, 6);
    lookup[0x94] = Instruction(InstructionType.sty, AddressMode.zpx, 4);
    lookup[0x95] = Instruction(InstructionType.sta, AddressMode.zpx, 4);
    lookup[0x96] = Instruction(InstructionType.stx, AddressMode.zpy, 4);
    lookup[0x97] = Instruction(InstructionType.sax, AddressMode.zpy, 4);
    lookup[0x98] = Instruction(InstructionType.tya, AddressMode.imp, 2);
    lookup[0x99] = Instruction(InstructionType.sta, AddressMode.aby, 5);
    lookup[0x9A] = Instruction(InstructionType.txs, AddressMode.imp, 2);
    lookup[0x9B] = Instruction(InstructionType.tas, AddressMode.aby, 5);
    lookup[0x9C] = Instruction(InstructionType.shy, AddressMode.abx, 5);
    lookup[0x9D] = Instruction(InstructionType.sta, AddressMode.abx, 5);
    lookup[0x9E] = Instruction(InstructionType.shx, AddressMode.aby, 5);
    lookup[0x9F] = Instruction(InstructionType.ahx, AddressMode.aby, 5);
    lookup[0xA0] = Instruction(InstructionType.ldy, AddressMode.imm, 2);
    lookup[0xA1] = Instruction(InstructionType.lda, AddressMode.izx, 6);
    lookup[0xA2] = Instruction(InstructionType.ldx, AddressMode.imm, 2);
    lookup[0xA3] = Instruction(InstructionType.lax, AddressMode.izx, 6);
    lookup[0xA4] = Instruction(InstructionType.ldy, AddressMode.zp0, 3);
    lookup[0xA5] = Instruction(InstructionType.lda, AddressMode.zp0, 3);
    lookup[0xA6] = Instruction(InstructionType.ldx, AddressMode.zp0, 3);
    lookup[0xA7] = Instruction(InstructionType.lax, AddressMode.zp0, 3);
    lookup[0xA8] = Instruction(InstructionType.tay, AddressMode.imp, 2);
    lookup[0xA9] = Instruction(InstructionType.lda, AddressMode.imm, 2);
    lookup[0xAA] = Instruction(InstructionType.tax, AddressMode.imp, 2);
    lookup[0xAB] = Instruction(InstructionType.lax, AddressMode.imm, 2);
    lookup[0xAC] = Instruction(InstructionType.ldy, AddressMode.abs, 4);
    lookup[0xAD] = Instruction(InstructionType.lda, AddressMode.abs, 4);
    lookup[0xAE] = Instruction(InstructionType.ldx, AddressMode.abs, 4);
    lookup[0xAF] = Instruction(InstructionType.lax, AddressMode.abs, 4);
    lookup[0xB0] = Instruction(InstructionType.bcs, AddressMode.rel, 2);
    lookup[0xB1] = Instruction(InstructionType.lda, AddressMode.izy, 5);
    lookup[0xB2] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xB3] = Instruction(InstructionType.lax, AddressMode.izy, 5);
    lookup[0xB4] = Instruction(InstructionType.ldy, AddressMode.zpx, 4);
    lookup[0xB5] = Instruction(InstructionType.lda, AddressMode.zpx, 4);
    lookup[0xB6] = Instruction(InstructionType.ldx, AddressMode.zpy, 4);
    lookup[0xB7] = Instruction(InstructionType.lax, AddressMode.zpy, 4);
    lookup[0xB8] = Instruction(InstructionType.clv, AddressMode.imp, 2);
    lookup[0xB9] = Instruction(InstructionType.lda, AddressMode.aby, 4);
    lookup[0xBA] = Instruction(InstructionType.tsx, AddressMode.imp, 2);
    lookup[0xBB] = Instruction(InstructionType.las, AddressMode.aby, 4);
    lookup[0xBC] = Instruction(InstructionType.ldy, AddressMode.abx, 4);
    lookup[0xBD] = Instruction(InstructionType.lda, AddressMode.abx, 4);
    lookup[0xBE] = Instruction(InstructionType.ldx, AddressMode.aby, 4);
    lookup[0xBF] = Instruction(InstructionType.lax, AddressMode.aby, 4);
    lookup[0xC0] = Instruction(InstructionType.cpy, AddressMode.imm, 2);
    lookup[0xC1] = Instruction(InstructionType.cmp, AddressMode.izx, 6);
    lookup[0xC2] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0xC3] = Instruction(InstructionType.dcp, AddressMode.izx, 8);
    lookup[0xC4] = Instruction(InstructionType.cpy, AddressMode.zp0, 3);
    lookup[0xC5] = Instruction(InstructionType.cmp, AddressMode.zp0, 3);
    lookup[0xC6] = Instruction(InstructionType.dec, AddressMode.zp0, 5);
    lookup[0xC7] = Instruction(InstructionType.dcp, AddressMode.zp0, 5);
    lookup[0xC8] = Instruction(InstructionType.iny, AddressMode.imp, 2);
    lookup[0xC9] = Instruction(InstructionType.cmp, AddressMode.imm, 2);
    lookup[0xCA] = Instruction(InstructionType.dex, AddressMode.imp, 2);
    lookup[0xCB] = Instruction(InstructionType.axs, AddressMode.imm, 2);
    lookup[0xCC] = Instruction(InstructionType.cpy, AddressMode.abs, 4);
    lookup[0xCD] = Instruction(InstructionType.cmp, AddressMode.abs, 4);
    lookup[0xCE] = Instruction(InstructionType.dec, AddressMode.abs, 6);
    lookup[0xCF] = Instruction(InstructionType.dcp, AddressMode.abs, 6);
    lookup[0xD0] = Instruction(InstructionType.bne, AddressMode.rel, 2);
    lookup[0xD1] = Instruction(InstructionType.cmp, AddressMode.izy, 5);
    lookup[0xD2] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xD3] = Instruction(InstructionType.dcp, AddressMode.izy, 8);
    lookup[0xD4] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0xD5] = Instruction(InstructionType.cmp, AddressMode.zpx, 4);
    lookup[0xD6] = Instruction(InstructionType.dec, AddressMode.zpx, 6);
    lookup[0xD7] = Instruction(InstructionType.dcp, AddressMode.zpx, 6);
    lookup[0xD8] = Instruction(InstructionType.cld, AddressMode.imp, 2);
    lookup[0xD9] = Instruction(InstructionType.cmp, AddressMode.aby, 4);
    lookup[0xDA] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xDB] = Instruction(InstructionType.dcp, AddressMode.aby, 7);
    lookup[0xDC] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0xDD] = Instruction(InstructionType.cmp, AddressMode.abx, 4);
    lookup[0xDE] = Instruction(InstructionType.dec, AddressMode.abx, 7);
    lookup[0xDF] = Instruction(InstructionType.dcp, AddressMode.abx, 7);
    lookup[0xE0] = Instruction(InstructionType.cpx, AddressMode.imm, 2);
    lookup[0xE1] = Instruction(InstructionType.sbc, AddressMode.izx, 6);
    lookup[0xE2] = Instruction(InstructionType.skb, AddressMode.imm, 2);
    lookup[0xE3] = Instruction(InstructionType.isc, AddressMode.izx, 8);
    lookup[0xE4] = Instruction(InstructionType.cpx, AddressMode.zp0, 3);
    lookup[0xE5] = Instruction(InstructionType.sbc, AddressMode.zp0, 3);
    lookup[0xE6] = Instruction(InstructionType.inc, AddressMode.zp0, 5);
    lookup[0xE7] = Instruction(InstructionType.isc, AddressMode.zp0, 5);
    lookup[0xE8] = Instruction(InstructionType.inx, AddressMode.imp, 2);
    lookup[0xE9] = Instruction(InstructionType.sbc, AddressMode.imm, 2);
    lookup[0xEA] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xEB] = Instruction(InstructionType.sbc, AddressMode.imm, 2);
    lookup[0xEC] = Instruction(InstructionType.cpx, AddressMode.abs, 4);
    lookup[0xED] = Instruction(InstructionType.sbc, AddressMode.abs, 4);
    lookup[0xEE] = Instruction(InstructionType.inc, AddressMode.abs, 6);
    lookup[0xEF] = Instruction(InstructionType.isc, AddressMode.abs, 6);
    lookup[0xF0] = Instruction(InstructionType.beq, AddressMode.rel, 2);
    lookup[0xF1] = Instruction(InstructionType.sbc, AddressMode.izy, 5);
    lookup[0xF2] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xF3] = Instruction(InstructionType.isc, AddressMode.izy, 8);
    lookup[0xF4] = Instruction(InstructionType.nop, AddressMode.zpx, 4);
    lookup[0xF5] = Instruction(InstructionType.sbc, AddressMode.zpx, 4);
    lookup[0xF6] = Instruction(InstructionType.inc, AddressMode.zpx, 6);
    lookup[0xF7] = Instruction(InstructionType.isc, AddressMode.zpx, 6);
    lookup[0xF8] = Instruction(InstructionType.sed, AddressMode.imp, 2);
    lookup[0xF9] = Instruction(InstructionType.sbc, AddressMode.aby, 4);
    lookup[0xFA] = Instruction(InstructionType.nop, AddressMode.imp, 2);
    lookup[0xFB] = Instruction(InstructionType.isc, AddressMode.aby, 7);
    lookup[0xFC] = Instruction(InstructionType.nop, AddressMode.abx, 4);
    lookup[0xFD] = Instruction(InstructionType.sbc, AddressMode.abx, 4);
    lookup[0xFE] = Instruction(InstructionType.inc, AddressMode.abx, 7);
    lookup[0xFF] = Instruction(InstructionType.isc, AddressMode.abx, 7);
  }

  int _inx() {
    x = (x + 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);
    return 0;
  }

  int _iny() {
    y = (y + 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: y == 0);
    _setFlag(negativeFlag, isFlagSet: (y & 0x80) != 0);
    return 0;
  }

  int _dex() {
    x = (x - 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);

    return 0;
  }

  int _dey() {
    y = (y - 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: y == 0);
    _setFlag(negativeFlag, isFlagSet: (y & 0x80) != 0);

    return 0;
  }

  int _bcc() {
    if (_getFlag(carryFlag) == 0) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bcs() {
    if (_getFlag(carryFlag) == 1) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _beq() {
    if (_getFlag(zeroFlag) == 1) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bmi() {
    if (_getFlag(negativeFlag) == 1) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bne() {
    if (_getFlag(zeroFlag) == 0) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bpl() {
    if (_getFlag(negativeFlag) == 0) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bvc() {
    if (_getFlag(overflowFlag) == 0) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _bvs() {
    if (_getFlag(overflowFlag) == 1) {
      cycles++;
      addrAbs = pc + addrRel;
      if ((addrAbs & 0xFF00) != (pc & 0xFF00)) cycles++;
      pc = addrAbs & 0xFFFF;
    }

    return 0;
  }

  int _pha() {
    write(0x0100 + stkp, a);
    stkp = (stkp - 1) & 0xFF;
    return 0;
  }

  int _php() {
    write(0x0100 + stkp, status | breakFlag | unusedFlag);
    stkp = (stkp - 1) & 0xFF;
    return 0;
  }

  int _pla() {
    stkp = (stkp + 1) & 0xFF;
    a = read(0x0100 + stkp);
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _plp() {
    stkp = (stkp + 1) & 0xFF;
    status = read(0x0100 + stkp);
    _setFlag(unusedFlag, isFlagSet: true);
    status &= ~breakFlag;
    return 0;
  }

  int _clc() {
    _setFlag(carryFlag, isFlagSet: false);
    return 0;
  }

  int _cld() {
    _setFlag(decimalModeFlag, isFlagSet: false);
    return 0;
  }

  int _cli() {
    _setFlag(disableInterruptsFlag, isFlagSet: false);
    return 0;
  }

  int _clv() {
    _setFlag(overflowFlag, isFlagSet: false);
    return 0;
  }

  int _sec() {
    _setFlag(carryFlag, isFlagSet: true);
    return 0;
  }

  int _sed() {
    _setFlag(decimalModeFlag, isFlagSet: true);
    return 0;
  }

  int _sei() {
    _setFlag(disableInterruptsFlag, isFlagSet: true);
    return 0;
  }

  int _tax() {
    x = a;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);
    return 0;
  }

  int _tay() {
    y = a;
    _setFlag(zeroFlag, isFlagSet: y == 0);
    _setFlag(negativeFlag, isFlagSet: (y & 0x80) != 0);
    return 0;
  }

  int _tsx() {
    x = stkp;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);
    return 0;
  }

  int _txa() {
    a = x;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _txs() {
    stkp = x;
    return 0;
  }

  int _tya() {
    a = y;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _nop() => 0;

  int _jmp() {
    pc = addrAbs;
    return 0;
  }

  int _jsr() {
    pc--;
    write(0x0100 + stkp, (pc >> 8) & 0x00FF);
    stkp = (stkp - 1) & 0xFF;
    write(0x0100 + stkp, pc & 0x00FF);
    stkp = (stkp - 1) & 0xFF;
    pc = addrAbs;
    return 0;
  }

  int _rts() {
    stkp = (stkp + 1) & 0xFF;
    final lowByte = read(0x0100 + stkp);
    stkp = (stkp + 1) & 0xFF;
    final highByte = read(0x0100 + stkp);
    pc = ((highByte << 8) | lowByte) + 1;
    return 0;
  }

  int _rti() {
    stkp = (stkp + 1) & 0xFF;
    status = read(0x0100 + stkp);
    status &= ~breakFlag;
    _setFlag(unusedFlag, isFlagSet: true);
    stkp = (stkp + 1) & 0xFF;
    final lowByte = read(0x0100 + stkp);
    stkp = (stkp + 1) & 0xFF;
    final highByte = read(0x0100 + stkp);
    pc = (highByte << 8) | lowByte;
    return 0;
  }

  int _bit() {
    _fetch();
    _setFlag(zeroFlag, isFlagSet: (a & fetched) == 0);
    _setFlag(negativeFlag, isFlagSet: (fetched & 0x80) != 0);
    _setFlag(overflowFlag, isFlagSet: (fetched & 0x40) != 0);
    return 0;
  }

  int _asl() {
    _fetch();
    final val = fetched << 1;
    _setFlag(carryFlag, isFlagSet: (val & 0x100) != 0);
    _setFlag(zeroFlag, isFlagSet: (val & 0xFF) == 0);
    _setFlag(negativeFlag, isFlagSet: (val & 0x80) != 0);
    if (_currentInstruction.addressMode == AddressMode.imp) {
      a = val & 0xFF;
    } else {
      write(addrAbs, val & 0xFF);
    }

    return 0;
  }

  int _lsr() {
    _fetch();
    _setFlag(carryFlag, isFlagSet: (fetched & 0x01) != 0);
    final val = (fetched >> 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: val == 0);
    _setFlag(negativeFlag, isFlagSet: false);
    if (_currentInstruction.addressMode == AddressMode.imp) {
      a = val;
    } else {
      write(addrAbs, val);
    }

    return 0;
  }

  int _rol() {
    _fetch();
    final val = ((fetched << 1) | _getFlag(carryFlag)) & 0xFF;
    _setFlag(carryFlag, isFlagSet: (fetched & 0x80) != 0);
    _setFlag(zeroFlag, isFlagSet: val == 0);
    _setFlag(negativeFlag, isFlagSet: (val & 0x80) != 0);
    if (_currentInstruction.addressMode == AddressMode.imp) {
      a = val;
    } else {
      write(addrAbs, val);
    }

    return 0;
  }

  int _ror() {
    _fetch();
    final val = ((_getFlag(carryFlag) << 7) | (fetched >> 1)) & 0xFF;
    _setFlag(carryFlag, isFlagSet: (fetched & 0x01) != 0);
    _setFlag(zeroFlag, isFlagSet: val == 0);
    _setFlag(negativeFlag, isFlagSet: (val & 0x80) != 0);
    if (_currentInstruction.addressMode == AddressMode.imp) {
      a = val;
    } else {
      write(addrAbs, val);
    }

    return 0;
  }

  int _inc() {
    _fetch();
    final val = (fetched + 1) & 0xFF;
    write(addrAbs, val);
    _setFlag(zeroFlag, isFlagSet: val == 0);
    _setFlag(negativeFlag, isFlagSet: (val & 0x80) != 0);
    return 0;
  }

  int _dec() {
    _fetch();
    final val = (fetched - 1) & 0xFF;
    write(addrAbs, val);
    _setFlag(zeroFlag, isFlagSet: val == 0);
    _setFlag(negativeFlag, isFlagSet: (val & 0x80) != 0);
    return 0;
  }

  int _ldx() {
    _fetch();
    x = fetched;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);
    return 0;
  }

  int _ldy() {
    _fetch();
    y = fetched;
    _setFlag(zeroFlag, isFlagSet: y == 0);
    _setFlag(negativeFlag, isFlagSet: (y & 0x80) != 0);
    return 0;
  }

  int _stx() {
    write(addrAbs, x);
    return 0;
  }

  int _sty() {
    write(addrAbs, y);
    return 0;
  }

  int _lax() {
    _fetch();
    a = fetched;
    x = a;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _sax() {
    write(addrAbs, a & x);
    return 0;
  }

  int _sre() {
    _fetch();
    _setFlag(carryFlag, isFlagSet: (fetched & 0x01) != 0);
    final temp = (fetched >> 1) & 0xFF;
    write(addrAbs, temp);
    a ^= temp;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _skb() {
    pc++;
    return 0;
  }

  int _xxx() => 0;

  int _brk() {
    pc++;
    _setFlag(disableInterruptsFlag, isFlagSet: true);
    write(0x0100 + stkp, (pc >> 8) & 0x00FF);
    stkp = (stkp - 1) & 0xFF;
    write(0x0100 + stkp, pc & 0x00FF);
    stkp = (stkp - 1) & 0xFF;

    write(0x0100 + stkp, status | breakFlag | unusedFlag);
    stkp = (stkp - 1) & 0xFF;

    pc = read(0xFFFE) | (read(0xFFFF) << 8);
    return 0;
  }

  int a = 0x00;
  int x = 0x00;
  int y = 0x00;
  int stkp = 0x00;
  int pc = 0x0000;
  int status = 0x00;

  int fetched = 0x00;
  int temp = 0x0000;
  int addrAbs = 0x0000;
  int addrRel = 0x00;
  int opcode = 0x00;
  int cycles = 0;
  int clockCount = 0;

  late Instruction _currentInstruction;

  Bus? bus;

  int carryFlag = 0x01;
  int zeroFlag = 0x02;
  int disableInterruptsFlag = 0x04;
  int decimalModeFlag = 0x08;
  int breakFlag = 0x10;
  int unusedFlag = 0x20;
  int overflowFlag = 0x40;
  int negativeFlag = 0x80;

  List<Instruction> lookup = List.generate(
    256,
    (i) => Instruction(InstructionType.xxx, AddressMode.imp, 2),
  );

  void connect(Bus bus) => this.bus = bus;

  int read(int address) => bus?.cpuRead(address) ?? 0x00;

  void write(int address, int data) => bus?.cpuWrite(address, data);

  @pragma('vm:prefer-inline')
  int _getFlag(int flag) => (status & flag) > 0 ? 1 : 0;

  @pragma('vm:prefer-inline')
  void _setFlag(int flag, {required bool isFlagSet}) =>
      isFlagSet ? status |= flag : status &= ~flag;

  String getFlags() {
    final buffer = StringBuffer()
      ..write(_getFlag(negativeFlag))
      ..write(_getFlag(overflowFlag))
      ..write(_getFlag(unusedFlag))
      ..write(_getFlag(breakFlag))
      ..write(_getFlag(decimalModeFlag))
      ..write(_getFlag(disableInterruptsFlag))
      ..write(_getFlag(zeroFlag))
      ..write(_getFlag(carryFlag));

    return '$buffer';
  }

  int get programCounter => pc;
  int get accumulator => a;
  int get xRegister => x;
  int get yRegister => y;
  int get stackPointer => stkp;

  String memoryDump() {
    final buffer = StringBuffer();
    for (var i = 0; i < 0xFFFF; i += 16) {
      buffer.write("0x${i.toRadixString(16).padLeft(4, '0').toUpperCase()}: ");
      for (var j = 0; j < 16; j++) {
        buffer.write(
          "${read(i + j).toRadixString(16).padLeft(2, '0').toUpperCase()} ",
        );
      }
      buffer.writeln();
    }

    return '$buffer';
  }

  void reset() {
    a = 0;
    x = 0;
    y = 0;
    stkp = 0xFD;
    status = 0x00 | unusedFlag | disableInterruptsFlag;
    addrAbs = 0xFFFC;
    final lowByte = read(addrAbs + 0);
    final highByte = read(addrAbs + 1);
    pc = (highByte << 8) | lowByte;
    addrRel = 0x0000;
    addrAbs = 0x0000;
    fetched = 0x00;
    cycles = 8;
  }

  void irq() {
    if (_getFlag(disableInterruptsFlag) == 0) {
      write(0x0100 + stkp, (pc >> 8) & 0x00FF);
      stkp = (stkp - 1) & 0xFF;
      write(0x0100 + stkp, pc & 0x00FF);
      stkp = (stkp - 1) & 0xFF;
      write(0x0100 + stkp, (status & ~breakFlag) | unusedFlag);
      stkp = (stkp - 1) & 0xFF;
      _setFlag(disableInterruptsFlag, isFlagSet: true);
      addrAbs = 0xFFFE;
      final lowByte = read(addrAbs + 0);
      final highByte = read(addrAbs + 1);
      pc = (highByte << 8) | lowByte;
      cycles = 7;
    }
  }

  void nmi() {
    write(0x0100 + stkp, (pc >> 8) & 0x00FF);
    stkp = (stkp - 1) & 0xFF;
    write(0x0100 + stkp, pc & 0x00FF);
    stkp = (stkp - 1) & 0xFF;
    write(0x0100 + stkp, (status & ~breakFlag) | unusedFlag);
    stkp = (stkp - 1) & 0xFF;
    _setFlag(disableInterruptsFlag, isFlagSet: true);
    addrAbs = 0xFFFA;
    final lowByte = read(addrAbs + 0);
    final highByte = read(addrAbs + 1);
    pc = (highByte << 8) | lowByte;
    cycles = 8;
  }

  void clock() {
    if (cycles == 0) {
      opcode = read(pc);
      status |= unusedFlag;
      pc = (pc + 1) & 0xFFFF;
      _currentInstruction = lookup[opcode];
      cycles = _currentInstruction.cycles;
      final addl1 = _executeAddressMode(_currentInstruction.addressMode);
      final addl2 = _executeInstruction(_currentInstruction.instructionType);
      cycles += addl1 & addl2;
      status |= unusedFlag;
    }
    cycles--;
    clockCount++;
  }

  @pragma('vm:prefer-inline')
  int _executeAddressMode(AddressMode mode) => switch (mode) {
    AddressMode.imp => _imp(),
    AddressMode.imm => _imm(),
    AddressMode.zp0 => _zp0(),
    AddressMode.zpx => _zpx(),
    AddressMode.zpy => _zpy(),
    AddressMode.rel => _rel(),
    AddressMode.abs => _abs(),
    AddressMode.abx => _abx(),
    AddressMode.aby => _aby(),
    AddressMode.ind => _ind(),
    AddressMode.izx => _izx(),
    AddressMode.izy => _izy(),
  };

  @pragma('vm:prefer-inline')
  int _executeInstruction(InstructionType type) => switch (type) {
    InstructionType.lda => _lda(),
    InstructionType.ldx => _ldx(),
    InstructionType.ldy => _ldy(),
    InstructionType.sta => _sta(),
    InstructionType.stx => _stx(),
    InstructionType.sty => _sty(),
    InstructionType.tax => _tax(),
    InstructionType.tay => _tay(),
    InstructionType.txa => _txa(),
    InstructionType.tya => _tya(),
    InstructionType.tsx => _tsx(),
    InstructionType.txs => _txs(),
    InstructionType.pha => _pha(),
    InstructionType.php => _php(),
    InstructionType.pla => _pla(),
    InstructionType.plp => _plp(),
    InstructionType.and => _and(),
    InstructionType.eor => _eor(),
    InstructionType.ora => _ora(),
    InstructionType.bit => _bit(),
    InstructionType.adc => _adc(),
    InstructionType.sbc => _sbc(),
    InstructionType.cmp => _cmp(),
    InstructionType.cpx => _cpx(),
    InstructionType.cpy => _cpy(),
    InstructionType.inc => _inc(),
    InstructionType.inx => _inx(),
    InstructionType.iny => _iny(),
    InstructionType.dec => _dec(),
    InstructionType.dex => _dex(),
    InstructionType.dey => _dey(),
    InstructionType.asl => _asl(),
    InstructionType.lsr => _lsr(),
    InstructionType.rol => _rol(),
    InstructionType.ror => _ror(),
    InstructionType.bcc => _bcc(),
    InstructionType.bcs => _bcs(),
    InstructionType.beq => _beq(),
    InstructionType.bmi => _bmi(),
    InstructionType.bne => _bne(),
    InstructionType.bpl => _bpl(),
    InstructionType.bvc => _bvc(),
    InstructionType.bvs => _bvs(),
    InstructionType.clc => _clc(),
    InstructionType.cld => _cld(),
    InstructionType.cli => _cli(),
    InstructionType.clv => _clv(),
    InstructionType.sec => _sec(),
    InstructionType.sed => _sed(),
    InstructionType.sei => _sei(),
    InstructionType.jmp => _jmp(),
    InstructionType.jsr => _jsr(),
    InstructionType.rts => _rts(),
    InstructionType.rti => _rti(),
    InstructionType.brk => _brk(),
    InstructionType.nop => _nop(),
    InstructionType.anc => _anc(),
    InstructionType.slo => _slo(),
    InstructionType.rla => _rla(),
    InstructionType.rra => _rra(),
    InstructionType.dcp => _dcp(),
    InstructionType.isc => _isc(),
    InstructionType.axs => _axs(),
    InstructionType.ahx => _ahx(),
    InstructionType.alr => _alr(),
    InstructionType.arr => _arr(),
    InstructionType.las => _las(),
    InstructionType.lax => _lax(),
    InstructionType.sax => _sax(),
    InstructionType.shx => _shx(),
    InstructionType.shy => _shy(),
    InstructionType.sre => _sre(),
    InstructionType.skb => _skb(),
    InstructionType.tas => _tas(),
    InstructionType.xaa => _xaa(),
    InstructionType.xxx => _xxx(),
  };

  bool complete() => cycles == 0;

  @pragma('vm:prefer-inline')
  int _imp() {
    fetched = a;
    return 0;
  }

  @pragma('vm:prefer-inline')
  int _imm() {
    addrAbs = pc;
    pc = (pc + 1) & 0xFFFF;
    return 0;
  }

  @pragma('vm:prefer-inline')
  int _zp0() {
    addrAbs = read(pc) & 0x00FF;
    pc = (pc + 1) & 0xFFFF;
    return 0;
  }

  @pragma('vm:prefer-inline')
  int _zpx() {
    addrAbs = (read(pc) + x) & 0x00FF;
    pc = (pc + 1) & 0xFFFF;
    return 0;
  }

  @pragma('vm:prefer-inline')
  int _zpy() {
    addrAbs = (read(pc) + y) & 0x00FF;
    pc = (pc + 1) & 0xFFFF;
    return 0;
  }

  int _rel() {
    addrRel = read(pc) & 0xFF;
    pc = (pc + 1) & 0xFFFF;
    if ((addrRel & 0x80) != 0) {
      addrRel |= 0xFF00;
    }
    return 0;
  }

  int _abs() {
    final lowByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final highByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    addrAbs = (highByte << 8) | lowByte;
    return 0;
  }

  int _abx() {
    final lowByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final highByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final baseAddress = (highByte << 8) | lowByte;
    addrAbs = (baseAddress + x) & 0xFFFF;
    if ((baseAddress & 0xFF00) != (addrAbs & 0xFF00)) return 1;
    return 0;
  }

  int _aby() {
    final lowByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final highByte = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final baseAddress = (highByte << 8) | lowByte;
    addrAbs = (baseAddress + y) & 0xFFFF;
    if ((baseAddress & 0xFF00) != (addrAbs & 0xFF00)) return 1;
    return 0;
  }

  int _ind() {
    final ptrLow = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final ptrHigh = read(pc);
    pc = (pc + 1) & 0xFFFF;
    final ptr = (ptrHigh << 8) | ptrLow;
    if (ptrLow == 0xFF) {
      addrAbs = (read(ptr & 0xFF00) << 8) | read(ptr);
    } else {
      addrAbs = (read(ptr + 1) << 8) | read(ptr);
    }
    return 0;
  }

  int _izx() {
    final temp = (read(pc) + x) & 0x00FF;
    pc = (pc + 1) & 0xFFFF;
    final lowByte = read(temp & 0x00FF);
    final highByte = read((temp + 1) & 0x00FF);
    addrAbs = (highByte << 8) | lowByte;
    return 0;
  }

  int _izy() {
    final temp = read(pc) & 0x00FF;
    pc = (pc + 1) & 0xFFFF;
    final lowByte = read(temp & 0x00FF);
    final highByte = read((temp + 1) & 0x00FF);
    final baseAddress = (highByte << 8) | lowByte;
    addrAbs = (baseAddress + y) & 0xFFFF;
    if ((baseAddress & 0xFF00) != (addrAbs & 0xFF00)) return 1;
    return 0;
  }

  @pragma('vm:prefer-inline')
  int _fetch() {
    if (_currentInstruction.addressMode != AddressMode.imp) {
      fetched = read(addrAbs);
    }
    return fetched;
  }

  int _adc() {
    _fetch();
    final tempSum = a + fetched + _getFlag(carryFlag);
    _setFlag(carryFlag, isFlagSet: tempSum > 0xFF);
    _setFlag(zeroFlag, isFlagSet: (tempSum & 0xFF) == 0);
    _setFlag(
      overflowFlag,
      isFlagSet: ((a ^ tempSum) & (fetched ^ tempSum) & 0x80) != 0,
    );
    _setFlag(negativeFlag, isFlagSet: (tempSum & 0x80) != 0);
    a = tempSum & 0xFF;
    return 1;
  }

  int _sbc() {
    _fetch();
    final value = fetched ^ 0xFF;
    final tempSum = a + value + _getFlag(carryFlag);
    _setFlag(carryFlag, isFlagSet: tempSum > 0xFF);
    _setFlag(zeroFlag, isFlagSet: (tempSum & 0xFF) == 0);
    _setFlag(
      overflowFlag,
      isFlagSet: ((tempSum ^ a) & (tempSum ^ value) & 0x80) != 0,
    );
    _setFlag(negativeFlag, isFlagSet: (tempSum & 0x80) != 0);
    a = tempSum & 0xFF;
    return 1;
  }

  int _and() {
    _fetch();
    a = a & fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0x00);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 1;
  }

  int _ora() {
    _fetch();
    a = a | fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0x00);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 1;
  }

  int _eor() {
    _fetch();
    a = a ^ fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0x00);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 1;
  }

  int _lda() {
    _fetch();
    a = fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0x00);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 1;
  }

  int _sta() {
    write(addrAbs, a);
    return 0;
  }

  int _cmp() {
    _fetch();
    final temp = a - fetched;
    _setFlag(carryFlag, isFlagSet: a >= fetched);
    _setFlag(zeroFlag, isFlagSet: (temp & 0xFF) == 0);
    _setFlag(negativeFlag, isFlagSet: (temp & 0x80) != 0);
    return 1;
  }

  int _cpx() {
    _fetch();
    final temp = x - fetched;
    _setFlag(carryFlag, isFlagSet: x >= fetched);
    _setFlag(zeroFlag, isFlagSet: (temp & 0xFF) == 0);
    _setFlag(negativeFlag, isFlagSet: (temp & 0x80) != 0);
    return 1;
  }

  int _cpy() {
    _fetch();
    final temp = y - fetched;
    _setFlag(carryFlag, isFlagSet: y >= fetched);
    _setFlag(zeroFlag, isFlagSet: (temp & 0xFF) == 0);
    _setFlag(negativeFlag, isFlagSet: (temp & 0x80) != 0);
    return 1;
  }

  int _rla() {
    _fetch();
    final oldCarry = _getFlag(carryFlag);
    final temp = ((fetched << 1) | oldCarry) & 0xFF;
    _setFlag(carryFlag, isFlagSet: (fetched & 0x80) != 0);
    write(addrAbs, temp);
    a = a & temp;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _slo() {
    _fetch();
    _setFlag(carryFlag, isFlagSet: (fetched & 0x80) != 0);
    final temp = (fetched << 1) & 0xFF;
    write(addrAbs, temp);
    a = a | temp;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _anc() {
    _fetch();
    a = a & fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    _setFlag(carryFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _rra() {
    _fetch();

    final newCarry = fetched & 0x01;
    final temp = ((_getFlag(carryFlag) << 7) | (fetched >> 1)) & 0xFF;
    _setFlag(carryFlag, isFlagSet: newCarry != 0);
    write(addrAbs, temp);

    final tempSum = a + temp + _getFlag(carryFlag);
    _setFlag(carryFlag, isFlagSet: tempSum > 0xFF);
    _setFlag(zeroFlag, isFlagSet: (tempSum & 0xFF) == 0);
    _setFlag(
      overflowFlag,
      isFlagSet: ((a ^ tempSum) & (temp ^ tempSum) & 0x80) != 0,
    );
    _setFlag(negativeFlag, isFlagSet: (tempSum & 0x80) != 0);
    a = tempSum & 0xFF;

    return 0;
  }

  int _dcp() {
    _fetch();
    final temp = (fetched - 1) & 0xFF;
    write(addrAbs, temp);
    final result = a - temp;
    _setFlag(carryFlag, isFlagSet: a >= temp);
    _setFlag(zeroFlag, isFlagSet: (result & 0xFF) == 0);
    _setFlag(negativeFlag, isFlagSet: (result & 0x80) != 0);
    return 0;
  }

  int _isc() {
    _fetch();
    final temp = (fetched + 1) & 0xFF;
    write(addrAbs, temp);
    final value = temp ^ 0xFF;
    final tempSum = a + value + _getFlag(carryFlag);
    _setFlag(carryFlag, isFlagSet: tempSum > 0xFF);
    _setFlag(zeroFlag, isFlagSet: (tempSum & 0xFF) == 0);
    _setFlag(
      overflowFlag,
      isFlagSet: (((tempSum ^ a) & (tempSum ^ value)) & 0x80) != 0,
    );
    _setFlag(negativeFlag, isFlagSet: (tempSum & 0x80) != 0);
    a = tempSum & 0xFF;
    return 0;
  }

  int _alr() {
    _fetch();
    a = a & fetched;
    _setFlag(carryFlag, isFlagSet: (a & 0x01) != 0);
    a = (a >> 1) & 0xFF;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: false);
    return 0;
  }

  int _arr() {
    _fetch();
    a = a & fetched;
    final oldCarry = _getFlag(carryFlag);
    a = ((a >> 1) | (oldCarry << 7)) & 0xFF;
    _setFlag(carryFlag, isFlagSet: (a & 0x40) != 0);
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    _setFlag(overflowFlag, isFlagSet: ((a & 0x40) ^ ((a & 0x20) << 1)) != 0);
    return 0;
  }

  int _axs() {
    _fetch();
    final temp = (a & x) - fetched;
    _setFlag(carryFlag, isFlagSet: temp >= 0);
    x = temp & 0xFF;
    _setFlag(zeroFlag, isFlagSet: x == 0);
    _setFlag(negativeFlag, isFlagSet: (x & 0x80) != 0);
    return 0;
  }

  int _ahx() {
    write(addrAbs, a & x & ((addrAbs >> 8) + 1));
    return 0;
  }

  int _las() {
    _fetch();
    final temp = fetched & stkp;
    a = temp;
    x = temp;
    stkp = temp;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  int _shx() {
    write(addrAbs, x & ((addrAbs >> 8) + 1));
    return 0;
  }

  int _shy() {
    write(addrAbs, y & ((addrAbs >> 8) + 1));
    return 0;
  }

  int _tas() {
    stkp = a & x;
    write(addrAbs, a & x & ((addrAbs >> 8) + 1));
    return 0;
  }

  int _xaa() {
    _fetch();
    a = (a | 0xEE) & x & fetched;
    _setFlag(zeroFlag, isFlagSet: a == 0);
    _setFlag(negativeFlag, isFlagSet: (a & 0x80) != 0);
    return 0;
  }

  Map<int, String> disassemble(int startAddress, int stopAtAddress) {
    var currentAddress = startAddress;
    var value = 0x00;
    var lowByte = 0x00;
    var highByte = 0x00;
    final mapLines = <int, String>{};

    String hex(int number, int digitCount) =>
        number.toRadixString(16).toUpperCase().padLeft(digitCount, '0');

    while (currentAddress <= stopAtAddress) {
      final lineAddress = currentAddress;
      final addressHex = '0x${hex(currentAddress, 4)}';
      final opcode = bus!.cpuRead(currentAddress, readOnly: true);

      currentAddress++;

      final instruction = lookup[opcode].instructionType.name.toUpperCase();
      final addressMode = lookup[opcode].addressMode;
      final addressModeName = addressMode.name.toUpperCase();

      var operand = '';

      if (addressMode == AddressMode.imp) {
        operand = '';
      } else if (addressMode == AddressMode.imm) {
        value = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '#\$${hex(value, 2)}';
      } else if (addressMode == AddressMode.zp0) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex(lowByte, 2)}';
      } else if (addressMode == AddressMode.zpx) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex(lowByte, 2)}, X';
      } else if (addressMode == AddressMode.zpy) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex(lowByte, 2)}, Y';
      } else if (addressMode == AddressMode.izx) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '(\$${hex(lowByte, 2)}, X)';
      } else if (addressMode == AddressMode.izy) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '(\$${hex(lowByte, 2)}), Y';
      } else if (addressMode == AddressMode.abs) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        highByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex((highByte << 8) | lowByte, 4)}';
      } else if (addressMode == AddressMode.abx) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        highByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex((highByte << 8) | lowByte, 4)}, X';
      } else if (addressMode == AddressMode.aby) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        highByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex((highByte << 8) | lowByte, 4)}, Y';
      } else if (addressMode == AddressMode.ind) {
        lowByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        highByte = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '(\$${hex((highByte << 8) | lowByte, 4)})';
      } else if (addressMode == AddressMode.rel) {
        value = bus!.cpuRead(currentAddress, readOnly: true);
        currentAddress++;
        operand = '\$${hex(value, 2)} [\$${hex(currentAddress + value, 4)}]';
      }

      final instructionSet =
          '$addressHex  ${instruction.padRight(6)}  ${operand.padRight(18)}  {$addressModeName}';

      mapLines[lineAddress] = instructionSet;
    }

    return mapLines;
  }

  CPUState saveState() => CPUState(
    a: a,
    x: x,
    y: y,
    stkp: stkp,
    pc: pc,
    status: status,
    fetched: fetched,
    temp: temp,
    addrAbs: addrAbs,
    addrRel: addrRel,
    opcode: opcode,
    cycles: cycles,
    clockCount: clockCount,
  );

  void restoreState(CPUState state) {
    a = state.a;
    x = state.x;
    y = state.y;
    stkp = state.stkp;
    pc = state.pc;
    status = state.status;
    fetched = state.fetched;
    temp = state.temp;
    addrAbs = state.addrAbs;
    addrRel = state.addrRel;
    opcode = state.opcode;
    cycles = state.cycles;
    clockCount = state.clockCount;
  }
}

class Instruction {
  Instruction(
    this.instructionType,
    this.addressMode,
    this.cycles,
  );

  final InstructionType instructionType;
  final AddressMode addressMode;
  final int cycles;
}

enum InstructionType {
  lda('Load Accumulator'),
  ldx('Load X Register'),
  ldy('Load Y Register'),
  sta('Store Accumulator'),
  stx('Store X Register'),
  sty('Store Y Register'),

  tax('Transfer Accumulator to X'),
  tay('Transfer Accumulator to Y'),
  txa('Transfer X to Accumulator'),
  tya('Transfer Y to Accumulator'),
  tsx('Transfer Stack Pointer to X'),
  txs('Transfer X to Stack Pointer'),

  pha('Push Accumulator'),
  php('Push Processor Status'),
  pla('Pull Accumulator'),
  plp('Pull Processor Status'),

  and('Logical AND'),
  eor('Exclusive OR'),
  ora('Logical Inclusive OR'),
  bit('Bit Test'),

  adc('Add with Carry'),
  sbc('Subtract with Carry'),
  cmp('Compare Accumulator'),
  cpx('Compare X Register'),
  cpy('Compare Y Register'),

  inc('Increment Memory'),
  inx('Increment X Register'),
  iny('Increment Y Register'),
  dec('Decrement Memory'),
  dex('Decrement X Register'),
  dey('Decrement Y Register'),

  asl('Arithmetic Shift Left'),
  lsr('Logical Shift Right'),
  rol('Rotate Left'),
  ror('Rotate Right'),

  bcc('Branch if Carry Clear'),
  bcs('Branch if Carry Set'),
  beq('Branch if Equal'),
  bmi('Branch if Minus'),
  bne('Branch if Not Equal'),
  bpl('Branch if Positive'),
  bvc('Branch if Overflow Clear'),
  bvs('Branch if Overflow Set'),

  clc('Clear Carry Flag'),
  cld('Clear Decimal Mode'),
  cli('Clear Interrupt Disable'),
  clv('Clear Overflow Flag'),
  sec('Set Carry Flag'),
  sed('Set Decimal Flag'),
  sei('Set Interrupt Disable'),

  jmp('Jump'),
  jsr('Jump to Subroutine'),
  rts('Return from Subroutine'),
  rti('Return from Interrupt'),

  brk('Force Interrupt'),
  nop('No Operation'),

  anc('AND + Set Carry'),
  slo('ASL + ORA'),
  rla('ROL + AND'),
  rra('ROR + ADC'),
  dcp('DEC + CMP'),
  isc('INC + SBC'),
  axs('(A & X) - Immediate'),

  ahx('AHX'),
  alr('ALR'),
  arr('ARR'),
  las('LAS'),
  lax('LAX'),
  sax('SAX'),
  shx('SHX'),
  shy('SHY'),

  sre('SRE'),
  skb('SKB'),
  tas('TAS'),
  xaa('XAA'),

  xxx('XXX - Unofficial');

  const InstructionType(this.fullName);

  final String fullName;

  String get abbr => name.toUpperCase();

  int Function() executeOperation(CPU cpu) => switch (this) {
    InstructionType.lda => cpu._lda,
    InstructionType.ldx => cpu._ldx,
    InstructionType.ldy => cpu._ldy,
    InstructionType.sta => cpu._sta,
    InstructionType.stx => cpu._stx,
    InstructionType.sty => cpu._sty,
    InstructionType.tax => cpu._tax,
    InstructionType.tay => cpu._tay,
    InstructionType.txa => cpu._txa,
    InstructionType.tya => cpu._tya,
    InstructionType.tsx => cpu._tsx,
    InstructionType.txs => cpu._txs,
    InstructionType.pha => cpu._pha,
    InstructionType.php => cpu._php,
    InstructionType.pla => cpu._pla,
    InstructionType.plp => cpu._plp,
    InstructionType.and => cpu._and,
    InstructionType.eor => cpu._eor,
    InstructionType.ora => cpu._ora,
    InstructionType.bit => cpu._bit,
    InstructionType.adc => cpu._adc,
    InstructionType.sbc => cpu._sbc,
    InstructionType.cmp => cpu._cmp,
    InstructionType.cpx => cpu._cpx,
    InstructionType.cpy => cpu._cpy,
    InstructionType.inc => cpu._inc,
    InstructionType.inx => cpu._inx,
    InstructionType.iny => cpu._iny,
    InstructionType.dec => cpu._dec,
    InstructionType.dex => cpu._dex,
    InstructionType.dey => cpu._dey,
    InstructionType.asl => cpu._asl,
    InstructionType.lsr => cpu._lsr,
    InstructionType.rol => cpu._rol,
    InstructionType.ror => cpu._ror,
    InstructionType.bcc => cpu._bcc,
    InstructionType.bcs => cpu._bcs,
    InstructionType.beq => cpu._beq,
    InstructionType.bmi => cpu._bmi,
    InstructionType.bne => cpu._bne,
    InstructionType.bpl => cpu._bpl,
    InstructionType.bvc => cpu._bvc,
    InstructionType.bvs => cpu._bvs,
    InstructionType.clc => cpu._clc,
    InstructionType.cld => cpu._cld,
    InstructionType.cli => cpu._cli,
    InstructionType.clv => cpu._clv,
    InstructionType.sec => cpu._sec,
    InstructionType.sed => cpu._sed,
    InstructionType.sei => cpu._sei,
    InstructionType.jmp => cpu._jmp,
    InstructionType.jsr => cpu._jsr,
    InstructionType.rts => cpu._rts,
    InstructionType.rti => cpu._rti,
    InstructionType.brk => cpu._brk,
    InstructionType.nop => cpu._nop,
    InstructionType.anc => cpu._anc,
    InstructionType.slo => cpu._slo,
    InstructionType.rla => cpu._rla,
    InstructionType.rra => cpu._rra,
    InstructionType.dcp => cpu._dcp,
    InstructionType.isc => cpu._isc,
    InstructionType.axs => cpu._axs,
    InstructionType.ahx => cpu._ahx,
    InstructionType.alr => cpu._alr,
    InstructionType.arr => cpu._arr,
    InstructionType.las => cpu._las,
    InstructionType.lax => cpu._lax,
    InstructionType.sax => cpu._sax,
    InstructionType.shx => cpu._shx,
    InstructionType.shy => cpu._shy,
    InstructionType.sre => cpu._sre,
    InstructionType.skb => cpu._skb,
    InstructionType.tas => cpu._tas,
    InstructionType.xaa => cpu._xaa,
    InstructionType.xxx => cpu._xxx,
  };
}

enum AddressMode {
  imp('Implied'),
  imm('Immediate'),
  zp0('Zero Page'),
  zpx('Zero Page,X'),
  zpy('Zero Page,Y'),
  rel('Relative'),
  abs('Absolute'),
  abx('Absolute,X'),
  aby('Absolute,Y'),
  ind('Indirect'),
  izx('Indexed Indirect (X,Indirect)'),
  izy('Indirect Indexed (Indirect,Y)');

  const AddressMode(this.fullName);

  final String fullName;

  String get abbr => name.toUpperCase();

  int Function() executeOperation(CPU cpu) => switch (this) {
    AddressMode.imp => cpu._imp,
    AddressMode.imm => cpu._imm,
    AddressMode.zp0 => cpu._zp0,
    AddressMode.zpx => cpu._zpx,
    AddressMode.zpy => cpu._zpy,
    AddressMode.rel => cpu._rel,
    AddressMode.abs => cpu._abs,
    AddressMode.abx => cpu._abx,
    AddressMode.aby => cpu._aby,
    AddressMode.ind => cpu._ind,
    AddressMode.izx => cpu._izx,
    AddressMode.izy => cpu._izy,
  };
}
