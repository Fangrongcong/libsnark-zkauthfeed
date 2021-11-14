// SPDX-License-Identifier: LGPL-3.0-only
// This file is LGPL3 Licensed
pragma solidity ^0.6.1;

/**
 * @title Elliptic curve operations on twist points for alt_bn128
 * @author Mustafa Al-Bassam (mus@musalbas.com)
 * @dev Homepage: https://github.com/musalbas/solidity-BN256G2
 */

library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Multiply a twist point by a scalar
     * @param s     Scalar to multiply by
     * @param pt1xx Coefficient 1 of x
     * @param pt1xy Coefficient 2 of x
     * @param pt1yx Coefficient 1 of y
     * @param pt1yy Coefficient 2 of y
     * @return (pt2xx, pt2xy, pt2yx, pt2yy)
     */
    function ECTwistMul(
        uint256 s,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        uint256 pt1zx = 1;
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            pt1xx = 1;
            pt1yx = 1;
            pt1zx = 0;
        } else {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
        }

        uint256[6] memory pt2 = _ECTwistMulJacobian(
            s,
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            pt1zx, 0
        );

        return _fromJacobian(
            pt2[PTXX], pt2[PTXY],
            pt2[PTYX], pt2[PTYY],
            pt2[PTZX], pt2[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */
    function GetFieldModulus() public pure returns (uint256) {
        return FIELD_MODULUS;
    }

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Add(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            addmod(xx, yx, FIELD_MODULUS),
            addmod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Div(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal view returns (uint256, uint256) {
        (yx, yy) = _FQ2Inv(yx, yy);
        return _FQ2Mul(xx, xy, yx, yy);
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }

    function _ECTwistMulJacobian(
        uint256 d,
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (uint256[6] memory pt2) {
        while (d != 0) {
            if ((d & 1) != 0) {
                pt2 = _ECTwistAddJacobian(
                    pt2[PTXX], pt2[PTXY],
                    pt2[PTYX], pt2[PTYY],
                    pt2[PTZX], pt2[PTZY],
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy);
            }
            (
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            ) = _ECTwistDoubleJacobian(
                pt1xx, pt1xy,
                pt1yx, pt1yy,
                pt1zx, pt1zy
            );

            d = d / 2;
        }
    }
}



// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }
    /// @return r the sum of two points of G2
    function addition(G2Point memory p1, G2Point memory p2) internal view returns (G2Point memory r) {
        (r.X[0], r.X[1], r.Y[0], r.Y[1]) = BN256G2.ECTwistAdd(p1.X[0],p1.X[1],p1.Y[0],p1.Y[1],p2.X[0],p2.X[1],p2.Y[0],p2.Y[1]);
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.6.1;

library GetVK200 {
    using Pairing for *;
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](50);
        data[0] = Pairing.G1Point(uint256(0x138ee0059dcce64fc49fff582890153f08ad5cd7d7ea9b5ee9b9ee6758923111), uint256(0x13806556b14c8d4b5a8d737ebdb6c781121747bfaa1f31e8730ad880c14c3bb5));
data[1] = Pairing.G1Point(uint256(0x06e7c92cbfa06203042339b5dce519e3970fdce85c1dbe1f180ac80dabae497e), uint256(0x2adab828b73e7da2b13b1ec11737bf9d6f05aa3d67f723f3e33784f2b559d2bf));
data[2] = Pairing.G1Point(uint256(0x13a5079740c6786c2b0de0e4964ccf5b74b4f7da57be07fd4af007b1713b9d2b), uint256(0x2928804c5d9788eed6a3a4576eb0a25d54f732c38310f253b4bbfccac30869dd));
data[3] = Pairing.G1Point(uint256(0x1b91bf3237da221e0f59a47f31334fda0d0595bd28a8ecb2639bf6301bc44f52), uint256(0x0d59800c9e9c8e101b7dd69f33126ec2f97d5635573995fd6ae175af28908e2b));
data[4] = Pairing.G1Point(uint256(0x3030f510601bc76d9180073085c35504c807eb6424862566e2389563bfed4372), uint256(0x2c30daec94bf745ecc534961ca15b716962f5afa311c100d5c424aadf1771c29));
data[5] = Pairing.G1Point(uint256(0x1d9ca15aae28c2a9f4428a2ee65d40e8bc6cdfd1e02b19846c1cf9f4c7347152), uint256(0x1eecef9433e342eb2924069224ead574ec7869c0887fb54de0045aabb19def98));
data[6] = Pairing.G1Point(uint256(0x0a5b122c67fa72cdf3ca361263ff198bf367f2c705854f71f9220bd045ac38e0), uint256(0x1ea0bac3a4635150e21528f13ab1b67f9e5c3836885897efa61ca86aa12c1b11));
data[7] = Pairing.G1Point(uint256(0x16b802e88513f79191c962f58df7834e3b5036c14b41e246e0c7068d63cf90e3), uint256(0x271a90371e361822c2cb31a5252d0de9c3e298bdd1ec5e3ad0cd3e534e708133));
data[8] = Pairing.G1Point(uint256(0x025a7504c322b0234263f3954f9f0526e5a6ea7555a1c496105e1a366a46375a), uint256(0x02b03a7b7cc3b1f2ac6e903b75107d3216c9c2e005d1f70d5dcc35b4edd8cbd8));
data[9] = Pairing.G1Point(uint256(0x1335dc16684308c5ad3e5dccaff513930c2811c15fd4619947caaa55a7bba902), uint256(0x196babd343398f950cf81a2fab558ac4031c09b5b6e388922b0a1bb44da13094));
data[10] = Pairing.G1Point(uint256(0x2f5ddd0118fef6ac10515e3ad7e5a1875259b26a39fed64b6a8f8301a8066f91), uint256(0x2ba4c5807dd2cdcc1b90a8eb55351e44db84feece0ccf2152ffe6228d423c75f));
data[11] = Pairing.G1Point(uint256(0x16c0a1bf9f19e7b9c03a19ae4dd3be9871e41fcd6da8de871a380167589e4ccc), uint256(0x2bf5ee1840660be339efd0b4116b80fc92068ded3ff97a658202d21b4f451735));
data[12] = Pairing.G1Point(uint256(0x261699b2e5c054a90f881cc4d2f26de9127fbc4eef43234fcdefb3a139148734), uint256(0x1c7e66a5df6147245eee857f60f42b0d094d4756ba2d06cf59ecc2918266826c));
data[13] = Pairing.G1Point(uint256(0x00a15600e8a905f20f6db2e785e96aee5ba77f4d5a1c3102b999896f5459b882), uint256(0x1d225236cd5b03bc3338f086b11c3c602a0a1c6affc0400d70b093e5a2631dcd));
data[14] = Pairing.G1Point(uint256(0x15b7083da04db342175b145475d2ed84286f964a5fa1b47ecb79eb9335c14bed), uint256(0x2b1376bae39763a27f1582383a2c272549cf6988a5125754e6d19b6fcba2e928));
data[15] = Pairing.G1Point(uint256(0x1b55cc5dc00e5a085b02eff285414fa5024ca276829b569d6bee460f01c8aa10), uint256(0x1a9a3bf0a08d8d1657a365109020bf3660633ad321d78fdd9eefa1c370d904be));
data[16] = Pairing.G1Point(uint256(0x0c2696599e279063c9fb7cb02fc24cfc43914b21b6decdb780f2709e72da2a18), uint256(0x0126034ca0588d62c9f08cf65996da491dfaa5bce8a40631b2e5f0c58785e962));
data[17] = Pairing.G1Point(uint256(0x2c8e44fe66ae0d2196ffa9c457920402d011b9c3a0d7d7b921f18886438f32ab), uint256(0x043e10c0917b438eeae23f0ea1734ce038ad09a31073c2fdaba22124c0ed5087));
data[18] = Pairing.G1Point(uint256(0x1b57d00cad3f2d294a061ec225fe5fd7034e6e93c00c9356b05ead0e4ed90a33), uint256(0x01c29b51d9f57a3001718b3781c4c369180fbb0740fb764115d003ded9bb98ff));
data[19] = Pairing.G1Point(uint256(0x0e13c5c97834a503d65ed0b63e03bff24f5ac491a82a61ab9a463f711f543242), uint256(0x2f2ca0a61a38454297b49a2a4e19ea63bc329353896113a42ba3ea8584b377b7));
data[20] = Pairing.G1Point(uint256(0x0b3e9db83246b3019c1ccd3d1246b3d97bdfa579a9614f5dd0380856fc9c64aa), uint256(0x1d2f03908bd52f2b06416197ab3d49bc0b456ceae97c6837cb8c0245684f0b24));
data[21] = Pairing.G1Point(uint256(0x0118ee2b83647d46a0f7401d7c4860ee97455490923f7615d24e5a559daecdf2), uint256(0x126095cd71ead937b238ca90d50769b15a9d5227934c10bf17b74e733ab6105a));
data[22] = Pairing.G1Point(uint256(0x0ec2abd8c4c4da0cd3525472b21bc50c8534fb0069169c3618b5cad783486755), uint256(0x12a636d0776ab155228a34b19cad81fe03000c38a7dfd29e31aef758870ffb80));
data[23] = Pairing.G1Point(uint256(0x0136371ac936d64d9c2d711c63d0218fd375b73b473a502f8e091ed079b0413c), uint256(0x2b52f9035a72b1089b99482d5b9cc114ef401aa47e823bc16b20637f7e78ad41));
data[24] = Pairing.G1Point(uint256(0x13c74a9a0d194cd18fafb7d6889dd5ff26cc819ad38c32f07bb79d70a874c606), uint256(0x2f4f720f6c7b7ae2d12779a699a6aed155ea4009c3f6e768ae47490713a519d3));
data[25] = Pairing.G1Point(uint256(0x2e12e6c17cbd554074e319e99040889818f985135018ee10aaf7277890cd8cfd), uint256(0x1505ca668136e3098b5aa8c39127d32be1654e86de4b6766cdd313e486057bd6));
data[26] = Pairing.G1Point(uint256(0x180a0d27c238999499b7241210a992df04bd71d2b771102f0ac6fc218e33d942), uint256(0x1e3dcc994d2eb5755adae650701c6b491482550bd9f46ff725e3da69e83c0601));
data[27] = Pairing.G1Point(uint256(0x047dbb4759f2d07a0a8c99b044df6e845f39ad07e171d1434f111d9dbf7fd8a5), uint256(0x28e76d79dc767b2a2260702564ee36199590ad575a5d73f0e7f21823c762ad44));
data[28] = Pairing.G1Point(uint256(0x195cb0bcbf7c90c0df7ca4317259f5fb1fa9ca7b9bcf998cf7e21a15546358e5), uint256(0x1e796c68a27796be46c500be7a0d5484e506342060b7692c31206073fe3bba84));
data[29] = Pairing.G1Point(uint256(0x21f1c91c42cd9dbde76099787f57f7d76dc872ea0177120fd940ec1915cfe0e8), uint256(0x210065ddaeb5427cb28edbeedecaa9a37e9eb39124426fefcdbbd2e3f88d099e));
data[30] = Pairing.G1Point(uint256(0x0cfdafc68553cc88ad88fab7e512a7d3a5585789bd6afed82f80002db9d55ad1), uint256(0x14c78f5f4c389bfa9d74a74151d03b3125a8b51418f4b8b7ae986782b89e2c8c));
data[31] = Pairing.G1Point(uint256(0x117829ed4feec4d5bc938e85b2c528e4dd53df78ea9a7b1d97ab72e243b395c0), uint256(0x292dd6466fb8f31f499c76ddd6ef08b0500669c35412e0ed6f248007bf375f15));
data[32] = Pairing.G1Point(uint256(0x2dd9271b0bafda75a7426a07ef1dc8edc2b1270d8e18f0c5e2a781fb887a90ef), uint256(0x023e1348837bd1e6e8a72082a5ff866991f1cc07b1c1bcaf602c54d5e2c3caba));
data[33] = Pairing.G1Point(uint256(0x140d55beadc112f5096fd8fd4d0fc15c36042094ade5822b963883863c58e3e0), uint256(0x2bb9d09f7bdcd93edd36492a5db20a74b2f7d3e1bd3f98b35963144a09d79808));
data[34] = Pairing.G1Point(uint256(0x1ff827fcc4ad3d7b3a489faa99d9f48de535bb1eb3ff4aa0df66f109223c3daf), uint256(0x01a7e6b9c5cf0cdb1cbcf374ee77c638af74cba05797506dca5109fdf13cce45));
data[35] = Pairing.G1Point(uint256(0x1a36f4de30b0cf2a0d0424744d3413f35bd0da65c6eaf72cb77e0ebd83cb6d37), uint256(0x0af6d43700d34f43a459a3abd2a638150ece08bb8a6c01e8ad9d798d1d372654));
data[36] = Pairing.G1Point(uint256(0x06ea3637c7ac72e34fbfdedf85af53ddb4acf98505c1d526c13a6e01db0e1a27), uint256(0x0bdb13fa761d5d3614cea50e8792685a3e587342c39a5f32218c1dce0b09e401));
data[37] = Pairing.G1Point(uint256(0x011d7091e529e17b27249974e05170d2e2773a5787f62e3a0679566fd9c1cc44), uint256(0x1330d7b611db8a4e1cc301512b294684977d649fd7949ffbf0c99cb5ec0ae52f));
data[38] = Pairing.G1Point(uint256(0x1f5e050b94cd5c5047a4680088c6a199c53da1c501a493d068a8a6d2ce434453), uint256(0x2cb69282727e9267460f207d200c156734baefea912b0e47333c25d54a91c1d3));
data[39] = Pairing.G1Point(uint256(0x12f1f011d16569449a20dfdd7221a7dd56d7ffea85bc13f5a00980c10cff6d86), uint256(0x1b4205318fb77f48732a89953a0e44574dd50a17b8198e0e6b5923a1e57bd6f2));
data[40] = Pairing.G1Point(uint256(0x05aa20c724faae0322bd1dedaf1c425857357346abbd24b9cc3e34bdc91b472f), uint256(0x1048b70558a3bf25f329b179c944f6df402d0dcce582254a2fb297be8967957a));
data[41] = Pairing.G1Point(uint256(0x19851a86af1e5a601f451720d93fa97b8dbde73763053596cb191d45fdd49c3a), uint256(0x047a2565e89f644f685405b6a8c7a5ca634929f776f81d98d081ae6f0704c7dc));
data[42] = Pairing.G1Point(uint256(0x2f20c36be72599609564af8e322816e045aad32ca25b6b32fa70a7225acfe475), uint256(0x0ed23b6afe75e9a8cfce1761d45a1bce6f6bfdff424f4d29dcda16ba3f234e22));
data[43] = Pairing.G1Point(uint256(0x298b640e563aa1d35e0862f03343700ddfeb5b79c54abba52fbc3c37dbcec4ed), uint256(0x06b429cccf080be211ba1b881b630adbfbd2ed46341ae5bf606fefa24064a662));
data[44] = Pairing.G1Point(uint256(0x149dcbb9c6a48eaacc437e9cd8f17a9c6359fca693640ccf9f45e1f558af2e1f), uint256(0x01510218141ac7137ad3cebdeebf601735c9f0949531675fdc24467deb1ac0b5));
data[45] = Pairing.G1Point(uint256(0x2d968f9928a753d244abcc678567e5e73c058b1b8b251679febb12374596dd2a), uint256(0x05f1ff2f2873ea79ccde073f8f2fff5261cc251b92404993f76c700b1966a6df));
data[46] = Pairing.G1Point(uint256(0x2f5e77621a5955928fff6c6c808c96fec85b90019f000f67cdb6d832b99929d9), uint256(0x2ab13ae04513f57b159a80ed7348c5afcf39ec1d92973bd1999a3b9247b4300d));
data[47] = Pairing.G1Point(uint256(0x28fe20c2d30a0746dfc9bc66531b3f54ecf38a32862c04521dcf248a7c076b59), uint256(0x173c63596fe87b777ed38db8cba536e8c0b9500f7a37bc21e3aefe71fc767ded));
data[48] = Pairing.G1Point(uint256(0x0d451b4ef060372cbfee08e0a97499079d6f8ddab8feb350a37e0c691e838cf1), uint256(0x27bfbf6868a4824e7a03c07d14d14c245b9add954d2433d44f3bd8500ec02e47));
data[49] = Pairing.G1Point(uint256(0x03d7ed4c129ba1f32f400d36af36a90e0081dd9588125bf3a6b72df981174053), uint256(0x16cf0a22d0d52a1d4ecee0fe5955989de78e9faec33f71be566b4e29d21451e7));
        Pairing.G1Point memory vk_x1 = Pairing.G1Point(m1, n1);
        for (uint i = 0; i < iinput.length; i++) {
            vk_x1 = Pairing.addition(vk_x1, Pairing.scalar_mul(data[i], uint(iinput[i])));
        }
        return (vk_x1.X,vk_x1.Y);
    }
}




contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point gamma_abc0;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() view internal returns (VerifyingKey memory vk) {
      vk.alpha = Pairing.G1Point(uint256(0x21414fbf101b7ddaa2b2b6fa27ff9cbcb5ed7bc299190d5afb6144fec906ea4a), uint256(0x204bb3602e237333e6c6888885cbac1e10767fa0a4d7394696664d69907fe374));
vk.beta = Pairing.G2Point([uint256(0x26ab8e530deef06df1e37f5315007981852e29a896ac1179e6d82a4c22257578), uint256(0x2e9f7a2a935dfc44a43842e0e79a897249279f98db6ac30855d2bc076bfea833)], [uint256(0x068206aaa389e150919aa9c893043b74841d96b3568a900bdfcc9bff7abfdaca), uint256(0x0a25df0833aa864a16d4b668d546574a9566f5e708267ada184713d179035328)]);
vk.gamma = Pairing.G2Point([uint256(0x050f3792ad4706e06ad662a71324f854205d9d894b6e38829c02af494287792f), uint256(0x16257970c2ecc6744017933eda3d0f6994c8101e3224dd321ac1d5b1476656a8)], [uint256(0x0a22457d9a1f9b454718f59a339ae95f4a56f8b07c3a65f0fc012e77e4e9b2fc), uint256(0x0a4be2d86c3e5f274740003295f89519d4cdea8e86843fd1da281ac27452b094)]);
vk.delta = Pairing.G2Point([uint256(0x29c2cee4c3c551dcd79a7ef13d322038acb423ef2d4da045915575a337d95e02), uint256(0x14255893fabbdb2896922d5cc747785be5585c62cf623162750f6e80b37a95c2)], [uint256(0x2c5a9fd9b84693fe0f6afaa2304a302c2632c5f9928b08783e4f45c66b0c3e48), uint256(0x153b9ff567cc246bf57a50126ec6003274e6d2f3733a20b2d93eb45e6aa148ab)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x04141c7a7693035f898f98544089826d674ab52106cde35d1fc98dfa1b277462), uint256(0x0d5bd600ec2ea46463a36b0ced455dfc048ca2fffe43e091055eabfec6a2a9a7));
    }
    
    function verify(uint32[] memory input1, Proof memory proof) internal view returns (uint) {
        //uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        uint x;
        uint y;
        (x, y) = GetVK200.getvk(vk_x.X, vk_x.Y,input1);
        vk_x = Pairing.G1Point(uint256(x), uint256(y));
        vk_x = Pairing.addition(vk_x, vk.gamma_abc0);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c, uint32[50] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](50);
      
        for(uint i = 0; i < 50; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

