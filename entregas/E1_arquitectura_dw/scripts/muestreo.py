"""Genera las muestras de PaySim e IEEE-CIS para la capa staging (< 100 MB c/u).

La consola de BigQuery solo acepta archivos de hasta ~100 MB, y los CSV
originales pesan más (PaySim ~470 MB, IEEE-CIS train_transaction ~650 MB).
Se muestrea por CUENTA y no por fila, para que el historial de cada cuenta
muestreada quede completo (es lo que necesita P1):

- PaySim: se conservan todas las transacciones cuya cuenta DESTINO cae en el
  10 % elegido por hash (solo el 0.15 % de las cuentas origen repite).
- IEEE-CIS: se conservan todas las transacciones de las tarjetas (card1) que
  caen en el 10 % elegido; identity se filtra a esos TransactionID.

No modifica ningún valor: las filas se copian tal cual (staging = dato crudo).

Uso:
    python muestreo.py --paysim PS_20174392719_1491204439457_log.csv \
                       --ieee-dir ieee-fraud-detection/ --salida muestras/
"""

import argparse
import csv
import zlib
from pathlib import Path

FRACCION = 10  # se conserva 1 de cada FRACCION cuentas


def elegida(clave: str) -> bool:
    return zlib.crc32(clave.encode()) % FRACCION == 0


def muestrear(entrada: Path, salida: Path, columna: str) -> set[str]:
    """Copia las filas cuya `columna` está en la muestra; devuelve la 1a columna de las filas copiadas."""
    ids, n = set(), 0
    with entrada.open(newline="") as f_in, salida.open("w", newline="") as f_out:
        lector = csv.reader(f_in)
        escritor = csv.writer(f_out)
        encabezado = next(lector)
        escritor.writerow(encabezado)
        idx = encabezado.index(columna)
        for fila in lector:
            if elegida(fila[idx]):
                escritor.writerow(fila)
                ids.add(fila[0])
                n += 1
    print(f"{salida.name}: {n:,} filas, {salida.stat().st_size / 1e6:.1f} MB")
    return ids


def filtrar_por_id(entrada: Path, salida: Path, ids: set[str]) -> None:
    with entrada.open(newline="") as f_in, salida.open("w", newline="") as f_out:
        lector = csv.reader(f_in)
        escritor = csv.writer(f_out)
        escritor.writerow(next(lector))
        n = 0
        for fila in lector:
            if fila[0] in ids:
                escritor.writerow(fila)
                n += 1
    print(f"{salida.name}: {n:,} filas, {salida.stat().st_size / 1e6:.1f} MB")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--paysim", type=Path, help="CSV original de PaySim")
    p.add_argument("--ieee-dir", type=Path, help="Carpeta con train_transaction.csv y train_identity.csv")
    p.add_argument("--salida", type=Path, default=Path("muestras"))
    args = p.parse_args()
    args.salida.mkdir(parents=True, exist_ok=True)

    if args.paysim:
        muestrear(args.paysim, args.salida / "paysim_muestra.csv", "nameDest")

    if args.ieee_dir:
        ids = muestrear(args.ieee_dir / "train_transaction.csv",
                        args.salida / "ieee_transaction_muestra.csv", "card1")
        filtrar_por_id(args.ieee_dir / "train_identity.csv",
                       args.salida / "ieee_identity_muestra.csv", ids)


if __name__ == "__main__":
    main()
