import os
from typing import List, Dict

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

from statsmodels.tsa.stattools import adfuller

from sklearn.metrics import mean_squared_error
from sklearn.metrics import mean_absolute_percentage_error


def path_to_work(end_directory: str = 'notebooks') -> None:
    curr_dir = os.path.dirname(os.path.realpath("__file__"))

    if curr_dir.endswith(end_directory):
        os.chdir('..')
        return f'Changed directory to: {curr_dir}'
    else:
        return f'Current working directory: {curr_dir}'


def plot_box_plot(df: pd.core.frame.DataFrame, data_set_name: str,
                  xlim=None) -> None:
    """
    Creates a seaborn boxplot including all dependent

    Args:
    data_set_name: Name of title for the boxplot
    xlim: Set upper and lower x-limits

    Returns:
        Box plot with specified data_frame, title, and x-limits
    """
    if xlim is not None:
        plt.xlim(*xlim)

    plt.title(f"Horizontal Boxplot {data_set_name}")
    plt.ylabel('Dependent Variables')
    plt.xlabel('Measurement x')
    ax = sns.boxplot(data=df,
                     orient='h',
                     palette='Set2',
                     notch=False)  # red squares for outliers

    plt.show()


def save_image(img: 'matplotlib', name: str,
               path: str = 'reports/images/') -> None:
    img.get_figure().savefig(f"reports/images/{name}.png")
    print(f"{name} saved at {path}.")


def save_dataframe(df: pd.core.frame.DataFrame,
                   path: str = 'data/cleansing/') -> None:
    df.to_csv(path_or_buf=path,
              sep=',',
              index=False,
              encoding='utf8')
    print(f"saved data at {path}")


def test_stationary(timeseries: pd.core.series.Series) -> None:
    # Calculate rolling statistics
    rolmean = timeseries.rolling(window=30, center=False).mean()
    rolstd = timeseries.rolling(window=30, center=False).std()

    # Plot rolling statistics
    plt.figure(figsize=(10, 6))
    plt.plot(timeseries, color='blue', label='Original')
    plt.plot(rolmean, color='red', label='Rolling Mean')
    plt.plot(rolstd, color='black', label='Rolling Std')
    plt.legend(loc='best')
    plt.title('Rolling Mean & Standard Deviation')
    plt.show()

    # Perform Dickey-Fuller test
    print('Results of Dickey-Fuller Test:')
    df_test = adfuller(timeseries, autolag=None)
    df_output = pd.Series(
        df_test[0:4],
        index=['Test Statistic',
               'p-value',
               'Lags Used',
               'Number of Observations Used'],
    )
    for k, v in df_test[4].items():
        df_output['Critical Value (%s)' % k] = v

    print(df_output)


def show_result_model(
    df_test: pd.core.frame.DataFrame,
    y_forecast,
    model_name: str,
    dict_results: Dict,
) -> None:
    future_forecast = pd.DataFrame(y_forecast,
                                   index=df_test.index,
                                   columns=['previsao'])
    mape = mean_absolute_percentage_error(df_test, y_forecast) * 100
    mse = mean_squared_error(df_test, y_forecast, squared=True)
    dict_results[model_name] = [mape, mse]

    pd.concat([df_test, future_forecast], axis=1).plot()

    plt.legend()
    plt.grid(True)
    plt.xlabel("Tempo (dias)", fontsize=20)
    plt.ylabel("Preço (R$)", fontsize=20)
    plt.title(f'MAPE = {mape:.2f} % | MSE = {mse:.2f}', fontsize=25)
