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
    function getvk(uint m1, uint n1, uint32[] memory iinput) public view returns (uint x1, uint  y1) {
        Pairing.G1Point[] memory data = new Pairing.G1Point[](60);
        data[0] = Pairing.G1Point(uint256(0x1e2eb2d843e44fdf663c14b6d63b335720ad166c25faebf27cd6bc5224749c8f), uint256(0x170b361bb61ced3086ea5018811f27bb9e8c3b614fcb040e52acb38b3b16179a));
data[1] = Pairing.G1Point(uint256(0x2cd1a144bd66691c1b6a821dbc36aaa91988273f66e5a72558139731ba52c07a), uint256(0x22a4f1b8832a1389fa5463d363a4c90c72337896bda2be113f0231b53bc1163b));
data[2] = Pairing.G1Point(uint256(0x0b3d7618348f97c39c62fa9573055bdb5a6a7630a566ca38949f38b931460ef1), uint256(0x01a519e5d87e2d01fe44ba166568c9069208e8f4ab260ceab3323b9bd4ff5c12));
data[3] = Pairing.G1Point(uint256(0x17f493c087cdaa5f722aa37898df61a7e357100e504dc530699f70143ec25c31), uint256(0x25dccecddf0c6bdf0b194b6b1b708cc9886510db47bacad4b2e9e7afd983f191));
data[4] = Pairing.G1Point(uint256(0x08aa98fc77d735d786bc27e6eafadcc8b332feb600b4dd27b91f9bd6b23b890b), uint256(0x027e240df3e58879c3d29bbafbaa165780aebdba7ed37ab7bc64e73411147fba));
data[5] = Pairing.G1Point(uint256(0x1e767c47dba83e9cdbc3e3df1caca56ca602bc284d07efdac6421adb2b770835), uint256(0x061ff4a4bed2bff978fa5d833a3167f170cae4671aa55a84aab922bf1cf19135));
data[6] = Pairing.G1Point(uint256(0x28ff45fd183204571fc6a739b3fc0bafb4202f6c0f5356b2c815c8cefb9e263b), uint256(0x2cb1ecb4e62eecdbcf789010e02cab29f18cd86cc120a3895563e9bf68e3e8c7));
data[7] = Pairing.G1Point(uint256(0x27a9ae588542e735d56fd45d5415acb3b3ff178804c3fc552c64a3aa020723ab), uint256(0x10cf9fe7eebc4876557afdf0319b74eddbc74c834593f4ae2a58f2d0a4610c8f));
data[8] = Pairing.G1Point(uint256(0x1ab88656b9f3d1bb6f71127ad20ac7cf5be3fc91645c61452848376e2c8d776f), uint256(0x0cbe1aa5f71a69c1ae8eefdd28cd1e684f23a6bcd453fa978dfc80db6927cf64));
data[9] = Pairing.G1Point(uint256(0x0377eaa83dc273ff36cfd6640a86990c235e54be562d7a510a9359e9c322d23e), uint256(0x29a84f532134f263c435fcb409367bef4e05f5b25b2c17a220b664e2b3824a1d));
data[10] = Pairing.G1Point(uint256(0x161f0f23b3a0f5db5bb18b55204730c9c07f551ae5ed709b9c3c4adbb39e3d68), uint256(0x09674a3d014eee395823fe0fcf26003a3fe55c242b6e927279736482ed8c6927));
data[11] = Pairing.G1Point(uint256(0x0d74e1d8d30fc91a5abf2e6ba8c8e410be11766496d84a1a3140bff469d262d2), uint256(0x296458b50960e2cfe6a0bb3fa87f66a4dd5e9027684d70c7537230b489d9b915));
data[12] = Pairing.G1Point(uint256(0x1d780116f84f4e3e7043587fbd5452a9af4977863f05fe189c8b4b5e7f3254e7), uint256(0x0f6630d670deca735d2ece66c809ced89fa066de3ba05b94e476703aa79708e7));
data[13] = Pairing.G1Point(uint256(0x005d6cd5487d2ddf05db31e590d02c831bbb7541e7a46bfadc55412aa4de0e51), uint256(0x0b8a4bab7daf40745f0e8a436438958661505e0f9017a3e108097b9627dbf4a5));
data[14] = Pairing.G1Point(uint256(0x10c0a465a57771cc9dd5cc0081c1377f5b76d39a853aef8094272901e3202460), uint256(0x1abab01cd9eacda299a6d5cb721fdfb7dbbea678ee0cd8676f438a64f2777e8e));
data[15] = Pairing.G1Point(uint256(0x1f37524a954fae5c3637179bd15c23be84f8efac134204c39e4da36e6eb41664), uint256(0x14265b3a5aec9c6274fde55961e8d075ae4ee3c71b5911f654e720bf23729d6b));
data[16] = Pairing.G1Point(uint256(0x026767dc70e6a6ed490512d8d910f92f0cfd4fff5a326ced202549d1c2072d04), uint256(0x194e1d4a83c2dadd300b99019397da973150e8e5d3fd4258afb99db08340481b));
data[17] = Pairing.G1Point(uint256(0x13be2f0085b459601b2294c5dc4c45b372644c4845f0594436b80c7b5fc8dd44), uint256(0x1da48546d2cc9a4be28128af31b21962114fe7907186391dcace3318d64566a7));
data[18] = Pairing.G1Point(uint256(0x0a98fb9d49deac596fe8220a2aa913fbfaf86a8ffdcda9fb0af4598d3ca2419a), uint256(0x1103142ffa011c656bbc52a5ba514ad8cab5ab95561dea8f44699091c32029d5));
data[19] = Pairing.G1Point(uint256(0x06cb32cb3c0cea10917d830cf8a6747feb1b0896a93179cdb6d70d0ae52ee4d2), uint256(0x1b44a18f146056b12804671ff0dde0b027532d2b580d6b98e39d9633da3defe9));
data[20] = Pairing.G1Point(uint256(0x130517ca5712f9ae0395c4be68c6138bb11d74082547135b89f879365ee57356), uint256(0x130de5728a4fcc2c6ef657ceb738acb63e693b6b9515299fa561424e90a028ad));
data[21] = Pairing.G1Point(uint256(0x00e67e2de3dca6b160b60817538e1d0811a1fb635c617148161e569ffbd1b2b0), uint256(0x2ebd4f2ec1b5c5940a3a2737d94d7f799dc07776154b0bdff41943178baca174));
data[22] = Pairing.G1Point(uint256(0x1302d19c6ac3e491a98bdb8baf5e557771a4cfd2ab34c689397ee6b868f33f2b), uint256(0x27cb82aa2c8d5239c4ae9bcb5eedb5f9117190d4aaca0d342b870877e31cd754));
data[23] = Pairing.G1Point(uint256(0x000fdce412b62f12cbca711dbbdaaceda80ca119e464e39ed0700d74c8283bb3), uint256(0x1e666154e102f382b14a7ea9a102d3b7138d644096e2d344719a611baa4ab6c6));
data[24] = Pairing.G1Point(uint256(0x081f46f489cfbdaa34c17fd9eaaa4d4546f7b3ceb3592f396235e0487b19e999), uint256(0x2add94644bf835f34631f03a91640509bc926f4289847728f8c3005ce83db56d));
data[25] = Pairing.G1Point(uint256(0x2f00de84ccb9f7c7a610e9d82b74be766f8de667a6a3c2e19ab2c64a0b360c8e), uint256(0x025df8a0881ca63e1624f969fcc4ae48cecded5cde9197922deae69415a6f1d9));
data[26] = Pairing.G1Point(uint256(0x261b7e5ab3926cab2448bc684cf76eaf772b74b710b396dc298bf531afcc711a), uint256(0x196b29c9e3bfa51a86cca256b81a0d4040a4936baa17cb5478ccbdaa1ca65bab));
data[27] = Pairing.G1Point(uint256(0x091bc39b9b40d97642e484816f9919a0eebe80876d1754d176fd9b19c385b370), uint256(0x1abf6e6e40f55e0088593eeb4422000579ae24ed9eced1054258eac96996ae6f));
data[28] = Pairing.G1Point(uint256(0x13ade35721fde303c8aaeb7957e9c9fe612a3282523f0e2f26e5f592f3208d65), uint256(0x0a28e8c702262333da76f2a6e626f43ceca986ad01f25b252da44bfafb47904c));
data[29] = Pairing.G1Point(uint256(0x217526445c62073804df1796eaa2b5e23b3e5a0a7d2d7699dfb9c71d4d045841), uint256(0x1d149a33de44d11f1369623b0a151a682e5bb2c92992bda83482632036884db5));
data[30] = Pairing.G1Point(uint256(0x1e53cec6b6fe40e92786b9a957cab450e384155c13233154f66b2dc5f28dc176), uint256(0x0d06f0ac156bc4f28fdc04b1b219334c74ed263616a8e0a3bf1d2c870364e14d));
data[31] = Pairing.G1Point(uint256(0x09177b904e3630bfa46f1724d30876cc3e394216a3a6fd7fd028bbcd9de82197), uint256(0x222963b42f22fc448d28862f80a2d615cbd62beafc44a7f46834c972169ad72a));
data[32] = Pairing.G1Point(uint256(0x13b08f9cd503f6790064d1d846e507f8c2c0f0818f75f7fe47560cdbd266ab32), uint256(0x27680505236bc4aa568db3b2e9c73c4d9c2ed74ccd3fdd5a7d3870f096eb9aac));
data[33] = Pairing.G1Point(uint256(0x1a4d4d26d420f6f56b6a8fe4d2b58d43981221b3ce744b648792b7e2e9fd331e), uint256(0x00489e5fca7f21da6f25264e2aa2d2024326f408afd06f2389e95b81cdcc8f74));
data[34] = Pairing.G1Point(uint256(0x0db590c8ae6b91a33bba4b819590f91fcd22dd47a1d2b3d5ad6223f399bc0b7f), uint256(0x17edc3afd17e1aef65cdba52a2669faeb6d0d5a96b044050ed8cf31fe98ba100));
data[35] = Pairing.G1Point(uint256(0x15f5eceaa7f3beaaff311d000c79a0ab704ab99d990e2422106036ee0b827317), uint256(0x12b502f3cfc0c5a8bc772da73bc0d6dffada83c14b8f3ae698bbba35399bfbfb));
data[36] = Pairing.G1Point(uint256(0x24a6dbb212be7aa0d6ec6437a6dae7ba694327d486e51652aebc2b8a4fd75e47), uint256(0x0fae40df552901e97bafa017387528a66b2c13853d141866294ea45041746fd1));
data[37] = Pairing.G1Point(uint256(0x0c3ad4964c545d6cf909d6f38bf5c6032e381136dc24fc5b2dad960482b34d93), uint256(0x0422cbc856dc54042e3e26f7d26fefa3c3f5e71a1ae0184e5572ef8cbfafce83));
data[38] = Pairing.G1Point(uint256(0x0eff62f774895fee18c5fb9aac9a5722cc7105929d388353a182328d1e4cd676), uint256(0x17a12b4d2b593ca5e9f99f9270f0ddbfcd09732edaa6ca251eb6fe9ee139ff5a));
data[39] = Pairing.G1Point(uint256(0x078eba46d640f1d608823e5d642e91161a2e8abf065a0f6e681c6f13d2d4e533), uint256(0x0687ea74638e198e503823e4135a4d0a708164d6f4010de3fc0c4f5e6a8ba9e9));
data[40] = Pairing.G1Point(uint256(0x1db8af6d5dd7e9acd0bcddb0fb9f8af5e4217d07e7e44d1465028ffbb86e7eda), uint256(0x0370b7953d658100cb1376009fb72b7b0482fb2ce16af7ebdf9c070a31e9e5c4));
data[41] = Pairing.G1Point(uint256(0x2f30b50217305cb2d79159eba02465c4b40e46228494dd98346716855641eaeb), uint256(0x12152da8f16815ed084e59e3cd4a7f937291c0018f7bee82684278ce5b385886));
data[42] = Pairing.G1Point(uint256(0x2cbe1ddc26fdf86d302ccf98cbeac5c38d26e53bbf9706980bd252238194ce4e), uint256(0x1a0cd23eb16ba788562c9b97da2e4ae73a190999a2a5621ae1d016a461fec84a));
data[43] = Pairing.G1Point(uint256(0x20f9da9298d7530d5f594c7d507a1039ed031f98ce81ff39912a73094ed3c712), uint256(0x2dabe650ac2cb88d3f3706aec76853ff019da29159deae4dd49fd293443136c4));
data[44] = Pairing.G1Point(uint256(0x2465b18a6176aabc0523a8cd5766e1e7038ec972c036138906293cab37080729), uint256(0x1efe585c2c4bfe6ac06a1ab1fc279ccb12d90608e8e8401b5f6ea82b85368a15));
data[45] = Pairing.G1Point(uint256(0x152f67fbdc21e52607a2be9840948edb8bf5d071cb678bd717b8cdf53cc3f233), uint256(0x1f5654cd9b9acee1da7e6366f902e14478ad495795386f5e1e7c3aeef493dc03));
data[46] = Pairing.G1Point(uint256(0x15f3404227bb994c818a59512520ac9d12c5dbeefb1744a95c442a0d8f2c72bc), uint256(0x1ac2d8ec1376598611cfe7741a996fcb16b9c913c519280cdaffa08556cc1ddc));
data[47] = Pairing.G1Point(uint256(0x2351e7a5d542cba7bbf9d0715d1d7fca9f2f31630b091d2dd7c5679077688e16), uint256(0x1a6d461d25916bf12cdf7a3b320bc76f5642859d8e2622852613af0fa510f5f4));
data[48] = Pairing.G1Point(uint256(0x055aacea87b42a7950abd22dbd717be96ebc72c8dd134c89e5f1daf3923854aa), uint256(0x0cf553d38af301a33751239786dfb789b405b1458ba49f2db06cdc468ee1c567));
data[49] = Pairing.G1Point(uint256(0x06d6508ebda7d537b0914a5f0d29e7ac19fef08103f2e58bef2eae91979fdc24), uint256(0x0e3156896bc45b14b30ab4f19012b32b550f6105fac1612c5230084bb8799a01));
data[50] = Pairing.G1Point(uint256(0x0f1b2442d0c86528bbdbadac55d874a80994fecd65b26aaf1401076866000469), uint256(0x06434dbb646746a7693646b497f21b177d1ea63ba768dd97aaf5ef798f4aa55e));
data[51] = Pairing.G1Point(uint256(0x0bc4eac00750defa9a687b081f85e28b64ea20d3db15981f772f2535555cd687), uint256(0x184d76e4a17676aa491c9bcd982f032f971091a9dd66eed0c207188f5c6b1ae6));
data[52] = Pairing.G1Point(uint256(0x0783f29b5f28e3db7b6452bb4fbd9993ebce00164dfd920b4b6c05c608a35cb5), uint256(0x23dbecfd96bb7aae480b9a8880c6c73aced890c5b8cfdd7ea3bc614a5a148290));
data[53] = Pairing.G1Point(uint256(0x2c752c5601a947d1b7568585918d280957792ad784a52c19f55efb1d30378490), uint256(0x2ad4ce8f474f67975b658fce673d7fe7e9508b447e78f0de5b04d7815c9060b0));
data[54] = Pairing.G1Point(uint256(0x015dc85ea687614ca5c15d12859316ddb371624a427a6d6870d204cc4ad51827), uint256(0x097dc8cffe85f478fe4ae0b8e5cea797082342d53669d36519f158e254d3b352));
data[55] = Pairing.G1Point(uint256(0x1ec50be9d97fb825526ddbb1640b51a2ccc449ccc4b7e3b7b7f84b555d127bcc), uint256(0x222e8255650481dff87ae64f72c46449da8b6d65d7d21a29ca607b5d54503877));
data[56] = Pairing.G1Point(uint256(0x2f05f8f606a59444db2dd6fc66f9cb9df9090ccc3b1d402337bb29e295fefdb6), uint256(0x0aa71a69257c900433b45c271fae6b167016d1db15ffb145e49fdeb2d7828e40));
data[57] = Pairing.G1Point(uint256(0x147826e104f04dff87ca4e56b086924717f9ab3c3e2e70d841c405d07a85fadc), uint256(0x2d6ba7030ce28efa820e64ae71881efa692b8f75bf1a42f3215dbcc8db3ec1d7));
data[58] = Pairing.G1Point(uint256(0x073d7a3d3c3c054ca6fdc88349022561e1c6620ec7aee11a98e7e9b8bf1155ce), uint256(0x016e25c4a278e173e0ba19fa3bf22534a84ab56558b3bb0e118950bb76553015));
data[59] = Pairing.G1Point(uint256(0x190d4cce5a46e3d1e580a18b4e0da458cbaa59202f94d9346f78eb367104e267), uint256(0x1544a7087a1367a88ea547551d8370f4bbd9a09185c72c1968afd3cff837b952));
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
      vk.alpha = Pairing.G1Point(uint256(0x1d37da219ea6b6a3bf31ac10905dbf6e937d06e27511c51d8ebcd53431e8943d), uint256(0x11b97b3f1d82cb04c9bc7546549a09513fbf7788834b19a60412e4558c7d70a0));
vk.beta = Pairing.G2Point([uint256(0x0c312214c98a7e9b4ff6fe249e6a24df331e44d8d3a58706e5ca0f6f0028a447), uint256(0x0b5bc1db57be3195a5e8dd21c1ad538ef64eb05da8729120d6059e7d80db1b45)], [uint256(0x2c6d07bac7dde202afb5af3c47d673927760f368f841bb592f304636eb0e521c), uint256(0x152b7134ffd15c7a9a3aeb0bf1af5028405857b9a8a1f24d3376fca85a1c87b3)]);
vk.gamma = Pairing.G2Point([uint256(0x279dccdd8a5d9c5fd457aaf43f1381f773dfb526a01bca24840ec93401c985c8), uint256(0x1acad5ef6beb4b0b71589c24f491c6742cc4b3939d347119dddab2e94e5c9a3c)], [uint256(0x03ab0a46ff3a68e67b400343d9288ac314466604634482cd0fe6081d8b3b699d), uint256(0x2de1ee5dbcf4beaebebce5334f68438cf239ebfc4bf4e75b6a4d819a5582a020)]);
vk.delta = Pairing.G2Point([uint256(0x129dc00fafdf7163ff7badf4e60f37f10d9ada46bc6e2ed85dd69c86ed7a43b8), uint256(0x1f2d2328b254ab5356b5d0d3102a9171cf44d1b50d02b150d0055b42634b934c)], [uint256(0x106a78a5148ce4bdde5c9344e349764150149839809ae1b2937cf52c84d1f2fb), uint256(0x2ae0be338417ca498fb56b61a4f9ef70c8b465ef05c891c11929b64e2823c3ee)]);
vk.gamma_abc0 = Pairing.G1Point(uint256(0x025f1d54fdfe47cb73c409200b480a47bd91c0beaf39279553ae7ac88cb26d66), uint256(0x150eb806112b4d6081beb99a5e28afe2b2103dd95cc382403526623c345c9c7f));
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
            uint[2] memory c, uint32[60] memory input
        ) public returns (bool r) {
        Proof memory proof;
        proof.a = Pairing.G1Point(a[0], a[1]);
        proof.b = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.c = Pairing.G1Point(c[0], c[1]);
        uint32[] memory inputValues1 = new uint32[](60);
      
        for(uint i = 0; i < 60; i++){
            inputValues1[i] = input[i];
        }
        
        if (verify(inputValues1,proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

